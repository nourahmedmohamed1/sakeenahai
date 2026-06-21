import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

/// A unique 128-bit UUID that identifies the Sakeenah AI app over BLE.
/// Every running instance of the app advertises this UUID so that other
/// Sakeenah users can discover it via BLE scanning.
const String kSakeenahServiceUuid = 'A5A50001-C4B6-4B0E-8C45-2F1A3E8D7B90';

/// Holds info about a discovered Sakeenah peer device.
class SakeenahPeer {
  final String deviceId;
  final String name;
  final int rssi;
  final DateTime lastSeen;

  SakeenahPeer({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.lastSeen,
  });
}

/// BLE discovery service for the SOS / Emergency tab.
///
/// - **Advertises** the Sakeenah service UUID so other Sakeenah users can
///   detect this device (proves the app is installed + Bluetooth is ON).
/// - **Scans** for nearby devices advertising the same UUID (finds only
///   other Sakeenah users with Bluetooth enabled).
///
/// Only used by the EmergencyTab — no other part of the app touches this.
class BleDiscoveryService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _cleanupTimer;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Currently visible Sakeenah peers, keyed by device ID for dedup.
  final Map<String, SakeenahPeer> _peers = {};

  /// Stream controller that emits the current list of live peers.
  final _peersController = StreamController<List<SakeenahPeer>>.broadcast();
  Stream<List<SakeenahPeer>> get peersStream => _peersController.stream;
  List<SakeenahPeer> get currentPeers => _peers.values.toList();

  /// How long before a peer that hasn't been re-seen is considered gone.
  static const _staleThreshold = Duration(seconds: 15);

  // ───────── public API ─────────

  /// Request BLE & location permissions, then start advertising + scanning.
  Future<void> start() async {
    if (_isRunning) return;

    // 1. Request permissions
    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('[BleDiscovery] Permissions denied — cannot start.');
      return;
    }

    // 2. Make sure Bluetooth adapter is on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      debugPrint('[BleDiscovery] Bluetooth is OFF — cannot start.');
      return;
    }

    _isRunning = true;

    // 3. Start BLE advertising (peripheral role)
    await _startAdvertising();

    // 4. Start BLE scanning (central role)
    _startScanning();

    // 5. Periodic cleanup of stale peers
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _removeStalePeers();
    });

    debugPrint('[BleDiscovery] Started — advertising + scanning.');
  }

  /// Stop advertising, scanning, and cleanup.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();

    try {
      await _peripheral.stop();
    } catch (e) {
      debugPrint('[BleDiscovery] Error stopping advertise: $e');
    }

    _peers.clear();
    _peersController.add([]);

    debugPrint('[BleDiscovery] Stopped.');
  }

  /// Release resources — call once, when the owner is permanently disposed.
  Future<void> dispose() async {
    await stop();
    await _peersController.close();
  }

  // ───────── internals ─────────

  Future<bool> _requestPermissions() async {
    // On Android 12+ (API 31) we need BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE,
    // BLUETOOTH_CONNECT.  On older Android and on iOS, BLUETOOTH is enough.
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // Accept if at least scan + advertise are granted (or permanently granted)
    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final advOk = statuses[Permission.bluetoothAdvertise]?.isGranted ?? false;
    final locOk = statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    final btOk = statuses[Permission.bluetooth]?.isGranted ?? false;

    // On iOS, only bluetooth + location matter
    return (scanOk && advOk && locOk) || (btOk && locOk);
  }

  Future<void> _startAdvertising() async {
    try {
      final advData = AdvertiseData(
        serviceUuid: kSakeenahServiceUuid,
        localName: 'Sakeenah',
      );
      await _peripheral.start(advertiseData: advData);
      debugPrint('[BleDiscovery] Advertising started.');
    } catch (e) {
      debugPrint('[BleDiscovery] Advertising error: $e');
    }
  }

  void _startScanning() {
    // Use flutter_blue_plus to scan for devices with our service UUID.
    // withServices filters to ONLY devices advertising the Sakeenah UUID.
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'حاج';

        _peers[id] = SakeenahPeer(
          deviceId: id,
          name: name,
          rssi: r.rssi,
          lastSeen: DateTime.now(),
        );
      }
      _peersController.add(_peers.values.toList());
    }, onError: (e) {
      debugPrint('[BleDiscovery] Scan error: $e');
    });

    // Start the actual scan — continuous, filtering by our UUID.
    FlutterBluePlus.startScan(
      withServices: [Guid(kSakeenahServiceUuid)],
      androidUsesFineLocation: true,
      continuousUpdates: true,
      removeIfGone: const Duration(seconds: 15),
    );
  }

  void _removeStalePeers() {
    final now = DateTime.now();
    final staleIds = <String>[];
    for (final entry in _peers.entries) {
      if (now.difference(entry.value.lastSeen) > _staleThreshold) {
        staleIds.add(entry.key);
      }
    }
    if (staleIds.isNotEmpty) {
      for (final id in staleIds) {
        _peers.remove(id);
      }
      _peersController.add(_peers.values.toList());
    }
  }
}
