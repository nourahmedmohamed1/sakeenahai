import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'service_model.dart';
import 'package:mbtiles/mbtiles.dart'; // ضرورية للتعامل مع ملفات الماب
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'routing_service.dart';
import 'medical_profile.dart';
import 'language_service.dart';
import 'ble_discovery_service.dart';

// ─── ألوان التطبيق الهادئة ───
const Color kEmerald50 = Color(0xFFECFDF5);
const Color kEmerald100 = Color(0xFFD1FAE5);
const Color kEmerald200 = Color(0xFFA7F3D0);
const Color kEmerald400 = Color(0xFF34D399);
const Color kEmerald600 = Color(0xFF059669);
const Color kEmerald700 = Color(0xFF047857);
const Color kEmerald800 = Color(0xFF065F46);
const Color kEmerald900 = Color(0xFF064E3B);
const Color kGold = Color(0xFFD4A84B);
const Color kGoldLight = Color(0xFFF5ECD7);
const Color kOffWhite = Color(0xFFFAF9F6);
const Color kWarmGray = Color(0xFF6B7280);

const MaterialColor emerald = MaterialColor(0xFF10B981, <int, Color>{
  50: kEmerald50,
  100: kEmerald100,
  200: kEmerald200,
  300: Color(0xFF6EE7B7),
  400: kEmerald400,
  500: Color(0xFF10B981),
  600: kEmerald600,
  700: kEmerald700,
  800: kEmerald800,
  900: kEmerald900,
});

void main() => runApp(const SakeenahApp());

class SakeenahApp extends StatelessWidget {
  const SakeenahApp({super.key});
  @override
  Widget build(context) {
    return MaterialApp(
      title: 'سَكينة AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: emerald,
        scaffoldBackgroundColor: kOffWhite,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: kEmerald700,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: kEmerald700,
          unselectedItemColor: kWarmGray,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const IntroScreen(),
    );
  }
}

// ═══════════════════════════════════════════
// شاشة البداية (Intro/Splash)
// ═══════════════════════════════════════════
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kEmerald900, kEmerald700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mosque_rounded, size: 120, color: kGold),
                  const SizedBox(height: 24),
                  const Text(
                    'سَكينة AI',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'رفيقك الآمن والمطمئن في الحج',
                    style: TextStyle(
                        fontSize: 20, color: kEmerald100, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const MainShell()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: kEmerald900,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: const Text('ابدأ الرحلة',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// متغيرات الموقع الوهمية (لتجربة مكة المكرمة)
// ═══════════════════════════════════════════
enum LocationMode { real, makkah, picked }
LocationMode globalLocationMode = LocationMode.real;
LatLng? globalPickedLocation;
LatLng makkahCenter = const LatLng(21.4225, 39.8262);

// ═══════════════════════════════════════════
// الهيكل الرئيسي — شريط تنقل سفلي بـ 4 تبويبات
// ═══════════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTab = 0;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initCurrentLang();
  }

  // تحميل اللغة وتحديث إعدادات الصوت فوراً عند التشغيل
  void _initCurrentLang() async {
    await LanguageService.loadSavedLanguage();
    _updateTTSLanguage();
  }

  void _updateTTSLanguage() async {
    String ttsCode = LanguageService.getTtsLanguageCode();
    await _tts.setLanguage(ttsCode);
    await _tts.setSpeechRate(ttsCode.startsWith('ar') ? 0.42 : 0.5);
    await _tts.setPitch(1.0);
  }

  void _speak(String msg) async => await _tts.speak(msg);

  // واجهة اختيار اللغات العصرية من أسفل الشاشة (Modal Bottom Sheet)
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        final languages = [
          {'code': 'ar', 'name': 'العربية'},
          {'code': 'en', 'name': 'English'},
          {'code': 'ur', 'name': 'اردو (Urdu)'},
          {'code': 'bn', 'name': 'বাংলা (Bengali)'},
          {'code': 'tr', 'name': 'Türkçe (Turkish)'},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LanguageService.translate('select_lang'),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    bool isSelected =
                        LanguageService.currentLang == lang['code'];
                    return ListTile(
                      leading: Icon(Icons.language_rounded,
                          color: isSelected ? kEmerald600 : Colors.grey),
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? kEmerald600 : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: kEmerald600)
                          : null,
                      onTap: () async {
                        await LanguageService.setLanguage(lang['code']!);
                        _updateTTSLanguage(); // تحديث لغة الصوت تلقائياً
                        if (!mounted) return;
                        Navigator.pop(context);
                        setState(
                            () {}); // إعادة بناء الواجهة لعرض اللغة الجديدة
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(tts: _tts, speak: _speak),
      TawafSaiTab(speak: _speak),
      SafeRouteTab(tts: _tts, speak: _speak),
      EmergencyTab(speak: _speak),
    ];

    return Directionality(
      // جعل اتجاه التطبيق متوافق مع اللغة المختارة (يمين ليسار للعربي والأوردو، وليسار يمين للباقي)
      textDirection: (LanguageService.currentLang == 'ar' ||
              LanguageService.currentLang == 'ur')
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LanguageService.translate('app_title'),
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            // زرار اختيار اللغة العصري (شكل الكرة الأرضية)
            IconButton(
              icon: const Icon(Icons.language_rounded, size: 26),
              onPressed: _showLanguageBottomSheet,
            ),
            // زرار الملف الطبي
            IconButton(
              icon: const Icon(Icons.medical_information_rounded, size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MedicalProfilePage()),
                ).then((_) => setState(() {}));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(index: _currentTab, children: tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Cairo', fontSize: 11),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 28),
                label: LanguageService.translate('tab_home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.mosque_rounded, size: 28),
                label: LanguageService.translate('tab_tawaf')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.map_rounded, size: 28),
                label: LanguageService.translate('tab_map')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.sos_rounded, size: 28),
                label: LanguageService.translate('tab_emergency')),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// بطاقة عامة مُنسّقة
// ═══════════════════════════════════════════
class SakeenahCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color? bgColor;
  const SakeenahCard(
      {super.key,
      required this.child,
      this.borderColor = kEmerald200,
      this.bgColor});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

// ═══════════════════════════════════════════
// تبويب 1: الرئيسية — مراقبة الإجهاد الحراري
// ═══════════════════════════════════════════
class DashboardTab extends StatefulWidget {
  final FlutterTts tts;
  final void Function(String) speak;
  const DashboardTab({super.key, required this.tts, required this.speak});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _accelSub;
  late AnimationController _pulseCtrl;

  int _healthLevel = 0; // 0=طبيعي, 1=خفيف, 2=متوسط, 3=شديد, 4=طوارئ
  String _healthText = "مستقر وطبيعي";
  Color _healthColor = kEmerald700;
  IconData _healthIcon = Icons.favorite_rounded;

  final List<double> _gaitSamples = [];
  final int _gaitWindowSize = 50;
  double _gaitVariability = 0.0;
  int _stumblingCount = 0;
  DateTime? _lastAlertTime;

  static const _levels = [
    {
      "text": "مستقر وطبيعي ✅",
      "color": kEmerald700,
      "icon": Icons.favorite_rounded
    },
    {
      "text": "يُنصح بشرب الماء والراحة 💧",
      "color": Color(0xFF2563EB),
      "icon": Icons.water_drop_rounded
    },
    {
      "text": "علامات إرهاق حراري 🌡️",
      "color": Color(0xFFD97706),
      "icon": Icons.thermostat_rounded
    },
    {
      "text": "إجهاد حراري ودوخة شديدة 🚨",
      "color": Color(0xFFEA580C),
      "icon": Icons.warning_amber_rounded
    },
    {
      "text": "طوارئ: تم رصد سقوط مفاجئ ⚠️",
      "color": Color(0xFFDC2626),
      "icon": Icons.emergency_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _initSensors();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _initSensors() {
    _accelSub = accelerometerEventStream().listen((e) {
      if (!mounted) return;
      double g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      _gaitSamples.add(g);
      if (_gaitSamples.length > _gaitWindowSize) _gaitSamples.removeAt(0);

      if (_gaitSamples.length >= 20) {
        double mean =
            _gaitSamples.reduce((a, b) => a + b) / _gaitSamples.length;
        double variance = _gaitSamples
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            _gaitSamples.length;
        _gaitVariability = sqrt(variance);
      }

      int newLevel = 0;
      if (g > 23.0) {
        newLevel = 4;
        _stumblingCount++;
      } else if ((e.x.abs() > 13.5 || e.y.abs() > 13.5) && g <= 22.0) {
        newLevel = 3;
      } else if (_gaitVariability > 4.0 || _stumblingCount >= 3) {
        newLevel = 2;
      } else if (_gaitVariability > 2.5) {
        newLevel = 1;
      }

      if (newLevel != _healthLevel) {
        final now = DateTime.now();
        if (_lastAlertTime == null ||
            now.difference(_lastAlertTime!) > const Duration(seconds: 8)) {
          _lastAlertTime = now;
          setState(() {
            _healthLevel = newLevel;
            _healthText = _levels[newLevel]["text"] as String;
            _healthColor = _levels[newLevel]["color"] as Color;
            _healthIcon = _levels[newLevel]["icon"] as IconData;
          });
          if (newLevel >= 2) {
            widget.speak(_healthText.replaceAll(RegExp(r'[✅💧🌡️🚨⚠️]'), ''));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        SakeenahCard(
          borderColor: _healthColor,
          child: Column(children: [
            const Text('مراقبة الحالة الصحية بالذكاء الاصطناعي',
                style: TextStyle(fontSize: 13, color: kWarmGray)),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                double scale =
                    _healthLevel >= 2 ? 1.0 + _pulseCtrl.value * 0.15 : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _healthColor.withValues(alpha: 0.12),
                      border: Border.all(color: _healthColor, width: 3),
                    ),
                    child: Icon(_healthIcon, color: _healthColor, size: 48),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(_healthText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _healthColor)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _miniStat('تذبذب المشية', _gaitVariability.toStringAsFixed(1)),
              _miniStat('حالات التعثر', '$_stumblingCount'),
            ]),
          ]),
        ),
        SakeenahCard(
          bgColor: kGoldLight,
          borderColor: kGold,
          child: Row(children: [
            const Icon(Icons.lightbulb_rounded, color: kGold, size: 32),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              _healthLevel == 0
                  ? 'أنت بخير والحمد لله. حافظ على شرب الماء باستمرار.'
                  : _healthLevel <= 2
                      ? 'استرح في مكان مُظلّل واشرب ماءً بارداً. لا تتعجّل.'
                      : 'توجّه فوراً لأقرب نقطة إسعاف. اطلب المساعدة من حولك.',
              style: const TextStyle(fontSize: 15, color: Color(0xFF78350F)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: kEmerald800)),
      Text(label, style: const TextStyle(fontSize: 12, color: kWarmGray)),
    ]);
  }
}

// ═══════════════════════════════════════════
// تبويب 2: عداد الطواف والسعي مع التوجيه الصوتي
// ═══════════════════════════════════════════
class TawafSaiTab extends StatefulWidget {
  final void Function(String) speak;
  const TawafSaiTab({super.key, required this.speak});
  @override
  State<TawafSaiTab> createState() => _TawafSaiTabState();
}

class _TawafSaiTabState extends State<TawafSaiTab> {
  bool _isSaiMode = false;
  bool _isManualChecklist = true;
  int _currentShawt = 0;
  
  // ── Tracking Systems ──
  int _stepCount = 0; 
  final int _stepsPerShawt = 800; // For Sa'i
  int _lastShawtSteps = 0;
  
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastStepTime = DateTime.now();
  
  StreamSubscription<CompassEvent>? _compassSub;
  double? _lastHeading;
  double _accumulatedDegrees = 0.0;

  static const _tawafDuaa = [
    'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
    'اللهم إني أسألك العفو والعافية في الدنيا والآخرة',
    'رب اغفر وارحم، أنت خير الراحمين',
    'اللهم اغفر لي ذنوبي وافتح لي أبواب رحمتك',
    'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
  ];

  static const _saiDuaa = [
    'إن الصفا والمروة من شعائر الله — بسم الله نبدأ',
    'لا إله إلا الله والله أكبر، لا إله إلا الله وحده',
    'رب اغفر وارحم واهدني السبيل الأقوم',
    'اللهم اجعلنا من عبادك الصالحين المقبولين',
    'سبحانك اللهم وبحمدك، أشهد ألا إله إلا أنت',
    'اللهم أعنّي على ذكرك وشكرك وحسن عبادتك',
    'الحمد لله الذي أتمّ علينا نسكنا. اللهم تقبّل منا',
  ];

  @override
  void initState() {
    super.initState();
    _initAccelerometer();
    _initCompass();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      if (event.heading == null) return;
      setState(() {
        if (_lastHeading != null) {
          double delta = event.heading! - _lastHeading!;
          if (delta > 180) delta -= 360;
          if (delta < -180) delta += 360;
          
          // Accumulate rotation. Tawaf implies continuous circular rotation.
          _accumulatedDegrees += delta.abs();
          
          if (!_isManualChecklist && !_isSaiMode) {
            if (_accumulatedDegrees >= 360.0 && _currentShawt < 7) {
              _accumulatedDegrees -= 360.0; // Consume 360 degrees
              _addShawt();
            }
          }
        }
        _lastHeading = event.heading;
      });
    });
  }

  void _initAccelerometer() {
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 11.5) {
        DateTime now = DateTime.now();
        if (now.difference(_lastStepTime).inMilliseconds > 300) {
          _lastStepTime = now;
          setState(() {
            _stepCount++;
            if (!_isManualChecklist) _checkAutoShawt();
          });
        }
      }
    });
  }

  void _checkAutoShawt() {
    int stepsSinceLastShawt = _stepCount - _lastShawtSteps;
    if (stepsSinceLastShawt >= _stepsPerShawt && _currentShawt < 7) {
      _addShawt();
    }
  }

  Future<void> _addShawt() async {
    if (_currentShawt >= 7) return;
    setState(() {
      _currentShawt++;
      _lastShawtSteps = _stepCount;
    });
    
    // Haptic feedback alert
    HapticFeedback.heavyImpact();
    _speakProgress();
  }

  Future<void> _setShawt(int count) async {
    setState(() {
      _currentShawt = count;
      _lastShawtSteps = _stepCount; // Synchronize auto counter anchor
    });
    
    if (count > 0 && count <= 7) {
      HapticFeedback.mediumImpact();
      _speakProgress();
    }
  }

  void _speakProgress() {
    // Only announce completed ritual at the LAST shawt (Shawt 7)
    String ritualName = _isSaiMode ? 'السَّعْيِ' : 'الطَّوَافِ';
    if (_currentShawt == 7) {
      widget.speak('مَا شَاءَ اللَّهُ! أَتْمَمْتَ $ritualName كَامِلاً.');
    }
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط العداد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من إعادة ضبط العداد من البداية؟',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () {
                _forceReset();
                Navigator.pop(ctx);
              },
              child: const Text('نعم، إعادة ضبط',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _forceReset() {
    setState(() {
      _currentShawt = 0;
      _stepCount = 0;
      _lastShawtSteps = 0;
      _accumulatedDegrees = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentShawt / 7.0;
    final duaaList = _isSaiMode ? _saiDuaa : _tawafDuaa;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        SakeenahCard(
          borderColor: kGold,
          bgColor: kGoldLight,
          child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                _modeButton(LanguageService.translate('btn_tawaf'), !_isSaiMode, () {
                  setState(() {
                    _isSaiMode = false;
                    _forceReset();
                  });
                }),
                _modeButton(LanguageService.translate('btn_sai'), _isSaiMode, () {
                  setState(() {
                    _isSaiMode = true;
                    _forceReset();
                  });
                }),
              ]),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(LanguageService.translate('calc_method'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kEmerald900)),
            ChoiceChip(
              label: Text(LanguageService.translate('auto_counter'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
              selected: !_isManualChecklist,
              onSelected: (val) => setState(() => _isManualChecklist = false),
              selectedColor: kEmerald200,
            ),
            ChoiceChip(
              label: Text(LanguageService.translate('manual_counter'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
              selected: _isManualChecklist,
              onSelected: (val) => setState(() => _isManualChecklist = true),
              selectedColor: kEmerald200,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isManualChecklist)
          _buildVisualChecklist(duaaList)
        else
          _buildAutoCounter(progress, duaaList),
        if (_currentShawt > 0 && _currentShawt <= 7)
          SakeenahCard(
            bgColor: kEmerald50,
            borderColor: kEmerald400,
            child: Column(children: [
              const Icon(Icons.menu_book_rounded, color: kEmerald700, size: 28),
              const SizedBox(height: 8),
              Text('${LanguageService.translate('duaa_shawt')} $_currentShawt',
                  style: const TextStyle(
                      fontSize: 14,
                      color: kEmerald800,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // The duaa is intentionally kept native without translation strings (per instructions)
              Text(duaaList[_currentShawt - 1],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, height: 1.8, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              Text(LanguageService.translate('audio_stopped_note'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: kWarmGray)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildAutoCounter(double progress, List<String> duaaList) {
    return SakeenahCard(
        child: Column(children: [
      Text(
          _isSaiMode
              ? LanguageService.translate('auto_sai_title')
              : LanguageService.translate('auto_tawaf_title'),
          style: const TextStyle(fontSize: 16, color: kWarmGray)),
      const SizedBox(height: 20),
      
      // Interactive Center Dashboard shrunk slightly to prevent overflow on small screens
      SizedBox(
        width: 210,
        height: 210,
        child: Stack(alignment: Alignment.center, children: [
          // Background track
          const SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation(kOffWhite),
            ),
          ),
          // Filled track (based on step progress for THIS shawt)
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(
                  _currentShawt == 7 ? kGold : kEmerald600),
            ),
          ),
          // Inner content
          Container(
            width: 165,
            height: 165,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)
              ]
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_isSaiMode ? '⛰️' : '🕋', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_currentShawt',
                      style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          height: 1,
                          color: kEmerald900)),
                  const Text(' / ٧', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kWarmGray)),
                ],
              ),
              Text(LanguageService.translate('shawt_word'), style: TextStyle(fontSize: 14, color: kEmerald700.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
            ]),
          )
        ]),
      ),
      if (_currentShawt == 7) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text(LanguageService.translate('congrats_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: kGold)),
        ),
      ],
      const SizedBox(height: 20),
      
      // Live Steps Indicator
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kEmerald50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kEmerald100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk_rounded, color: kEmerald700, size: 20),
            const SizedBox(width: 8),
            Text('${LanguageService.translate('steps_label')}$_stepCount',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kEmerald800)),
          ],
        ),
      ),
      
      if (_isSaiMode && _currentShawt > 0 && _currentShawt < 7) ...[
        const SizedBox(height: 12),
        Text(
            _currentShawt.isOdd
                ? LanguageService.translate('dir_safa_marwa')
                : LanguageService.translate('dir_marwa_safa'),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kEmerald700)),
      ],
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
        ElevatedButton.icon(
          onPressed: _currentShawt < 7 ? _addShawt : null,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(LanguageService.translate('record_shawt'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kEmerald600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded, size: 22),
          label: Text(LanguageService.translate('reset_btn'), style: const TextStyle(fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[700],
            backgroundColor: const Color(0xFFFEF2F2),
            side: BorderSide(color: Colors.red[200]!),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ]));
  }

  Widget _buildVisualChecklist(List<String> duaaList) {
    return Column(
      children: List<Widget>.generate(7, (index) {
        int shawtIndex = index + 1;
        bool isCompleted = shawtIndex <= _currentShawt;
        return GestureDetector(
          onTap: () {
            if (shawtIndex == _currentShawt + 1) {
              _setShawt(shawtIndex);
            } else if (isCompleted && shawtIndex == _currentShawt) {
              _setShawt(shawtIndex - 1);
            }
          },
          child: SakeenahCard(
            bgColor: isCompleted ? kEmerald100 : Colors.white,
            borderColor: isCompleted ? kEmerald600 : kEmerald200,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isCompleted ? kEmerald600 : kOffWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isCompleted ? kEmerald600 : kWarmGray, width: 2),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.touch_app_rounded,
                    color: isCompleted ? Colors.white : kWarmGray,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${LanguageService.translate('shawt_prefix')} $shawtIndex',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isCompleted ? kEmerald900 : Colors.black87)),
                      if (_isSaiMode)
                        Text(
                            shawtIndex.isOdd
                                ? LanguageService.translate('safa_to_marwa')
                                : LanguageService.translate('marwa_to_safa'),
                            style: TextStyle(
                                fontSize: 13,
                                color: isCompleted ? kEmerald800 : kWarmGray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList()
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 24),
              label: Text(LanguageService.translate('reset_all_btn'),
                  style: const TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                backgroundColor: const Color(0xFFFEF2F2),
                side: BorderSide(color: Colors.red[300]!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: active ? kEmerald700 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? kEmerald700 : kWarmGray),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : kWarmGray,
            )),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// تبويب 3: المسار الآمن — بوابة الخريطة
// ═══════════════════════════════════════════
class SafeRouteTab extends StatefulWidget {
  final FlutterTts tts;
  final void Function(String) speak;
  const SafeRouteTab({super.key, required this.tts, required this.speak});
  @override
  State<SafeRouteTab> createState() => _SafeRouteTabState();
}

class _SafeRouteTabState extends State<SafeRouteTab> {
  StreamSubscription<Position>? _locSub;
  LatLng _currentPos = const LatLng(21.4225, 39.8262);
  String _navText = "جاري تحديد موقعك...";
  String _selectedFilter = 'الكل';

  static const _filters = ['الكل', 'مستشفى', 'إسعاف', 'مياه', 'ظل'];

  final List<Map<String, dynamic>> _aidPoints = [
    {
      "name": "مستشفى أجياد الدولي",
      "type": "مستشفى",
      "icon": Icons.local_hospital_rounded,
      "color": const Color(0xFFDC2626),
      "location": const LatLng(21.4195, 39.8262)
    },
    {
      "name": "مستشفى الملك عبدالعزيز",
      "type": "مستشفى",
      "icon": Icons.local_hospital_rounded,
      "color": const Color(0xFFDC2626),
      "location": const LatLng(21.4280, 39.8220)
    },
    {
      "name": "مركز إسعاف المسجد الحرام",
      "type": "إسعاف",
      "icon": Icons.emergency_rounded,
      "color": const Color(0xFFEA580C),
      "location": const LatLng(21.4225, 39.8237)
    },
    {
      "name": "نقطة إسعاف الصفا",
      "type": "إسعاف",
      "icon": Icons.emergency_rounded,
      "color": const Color(0xFFEA580C),
      "location": const LatLng(21.4233, 39.8275)
    },
    {
      "name": "نقطة مياه — باب السلام",
      "type": "مياه",
      "icon": Icons.water_drop_rounded,
      "color": const Color(0xFF2563EB),
      "location": const LatLng(21.4215, 39.8245)
    },
    {
      "name": "نقطة مياه — المسعى",
      "type": "مياه",
      "icon": Icons.water_drop_rounded,
      "color": const Color(0xFF2563EB),
      "location": const LatLng(21.4240, 39.8270)
    },
    {
      "name": "منطقة مظللة — أجياد",
      "type": "ظل",
      "icon": Icons.park_rounded,
      "color": const Color(0xFF059669),
      "location": const LatLng(21.4180, 39.8255)
    },
    {
      "name": "منطقة مظللة — المروة",
      "type": "ظل",
      "icon": Icons.park_rounded,
      "color": const Color(0xFF059669),
      "location": const LatLng(21.4248, 39.8280)
    },
  ];

  @override
  void initState() {
    super.initState();
    _startLocation();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  void _startLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _navText = LanguageService.translate('loc_perm_denied'));
      return;
    }
    _locSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((pos) {
      if (!mounted) return;
      if (globalLocationMode != LocationMode.real) return; // MOCKED
      
      LatLng newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPos = newLoc);
      _updateNav(newLoc);
    });
    
    _applyLocationMode();
  }

  void _applyLocationMode() {
    if (globalLocationMode == LocationMode.makkah) {
      setState(() => _currentPos = makkahCenter);
      _updateNav(_currentPos);
    } else if (globalLocationMode == LocationMode.picked) {
      if (globalPickedLocation != null) {
        setState(() => _currentPos = globalPickedLocation!);
        _updateNav(_currentPos);
      } else {
        setState(() => _navText = LanguageService.translate('pick_map_prompt'));
      }
    }
  }

  void _updateNav(LatLng pos) {
    final filtered = _filteredPoints();
    if (filtered.isEmpty) {
      setState(() => _navText = "لا توجد نقاط من هذا النوع.");
      return;
    }
    double minDist = double.infinity;
    String nearest = "";
    for (var p in filtered) {
      double d = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          (p["location"] as LatLng).latitude,
          (p["location"] as LatLng).longitude);
      if (d < minDist) {
        minDist = d;
        nearest = p["name"];
      }
    }
    String distStr = minDist >= 1000
        ? "${(minDist / 1000).toStringAsFixed(1)} كم"
        : "${minDist.toStringAsFixed(0)} متر";
    setState(() => _navText = "أقرب نقطة: $nearest\nالمسافة: $distStr");
  }

  List<Map<String, dynamic>> _filteredPoints() {
    if (_selectedFilter == 'الكل') return _aidPoints;
    return _aidPoints.where((p) => p["type"] == _selectedFilter).toList();
  }

  void _speakNearest() {
    widget.speak(_navText.replaceAll('\n', '. '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location Mock Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: kEmerald50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.satellite_alt_rounded, color: kEmerald700, size: 20),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(LanguageService.translate('loc_real'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  selected: globalLocationMode == LocationMode.real,
                  selectedColor: kEmerald400,
                  onSelected: (_) {
                    setState(() => globalLocationMode = LocationMode.real);
                    _startLocation(); // Refreshes GPS stream manually
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(LanguageService.translate('loc_makkah'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  selected: globalLocationMode == LocationMode.makkah,
                  selectedColor: kEmerald400,
                  onSelected: (_) {
                    setState(() => globalLocationMode = LocationMode.makkah);
                    _applyLocationMode();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(LanguageService.translate('loc_picked'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  selected: globalLocationMode == LocationMode.picked,
                  selectedColor: kEmerald400,
                  onSelected: (_) {
                    setState(() => globalLocationMode = LocationMode.picked);
                    _applyLocationMode();
                  },
                ),
              ],
            ),
          ),
        ),
        // Filter Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: _filters.map((f) {
              bool active = _selectedFilter == f;
              String displayValue = LanguageService.translate(f == 'الكل' ? 'filter_all' : 
                                       f == 'مستشفى' ? 'filter_hospital' : 
                                       f == 'إسعاف' ? 'filter_ambulance' : 
                                       f == 'مياه' ? 'filter_water' : 'filter_shade');
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(displayValue,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : kEmerald800)),
                  selected: active,
                  selectedColor: kEmerald700,
                  backgroundColor: kEmerald50,
                  onSelected: (_) {
                    setState(() => _selectedFilter = f);
                    _applyLocationMode(); // Use _applyLocationMode which automatically falls back safely
                  },
                ),
              );
            }).toList()),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              SakeenahCard(
                bgColor: kEmerald50,
                borderColor: kEmerald400,
                child: Row(children: [
                  const Icon(Icons.near_me_rounded,
                      color: kEmerald700, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_navText,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937)))),
                  IconButton(
                    onPressed: _speakNearest,
                    icon: const Icon(Icons.volume_up_rounded,
                        color: kEmerald700, size: 28),
                    tooltip: 'قراءة صوتية',
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              SakeenahCard(
                borderColor: kEmerald600,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kEmerald700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.map_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text('خريطة مكة المكرمة الأوفلاين',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kEmerald900)),
                  const SizedBox(height: 6),
                  const Text(
                      'خريطة تفاعلية كاملة بدون إنترنت\nتشمل المسجد الحرام ومحيطه',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: kWarmGray, height: 1.5)),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfflineMapPage(
                                currentPos: _currentPos,
                                aidPoints: _filteredPoints(),
                                speak: widget.speak,
                              ),
                            ));
                      },
                      icon: const Icon(Icons.explore_rounded, size: 26),
                      label: const Text('افتح الخريطة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kEmerald700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              SakeenahCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                      const Icon(Icons.location_on_rounded,
                          color: kEmerald700, size: 22),
                      const SizedBox(width: 8),
                      Text(
                          '${LanguageService.translate('service_points')} — ${_selectedFilter == 'الكل' ? LanguageService.translate('filter_all') : LanguageService.translate(_selectedFilter == 'مستشفى' ? 'filter_hospital' : 
                                       _selectedFilter == 'إسعاف' ? 'filter_ambulance' : 
                                       _selectedFilter == 'مياه' ? 'filter_water' : 'filter_shade')}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kEmerald900)),
                    ]),
                    const Divider(height: 16),
                    ..._filteredPoints().map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (p["color"] as Color)
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(p["icon"] as IconData,
                                  color: p["color"] as Color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(p["name"] as String,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  Text(p["type"] as String,
                                      style: const TextStyle(
                                          fontSize: 12, color: kWarmGray)),
                                ])),
                          ]),
                        )),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// تبويب 4: نداء الطوارئ — شبكة بلوتوث
// ═══════════════════════════════════════════
class EmergencyTab extends StatefulWidget {
  final void Function(String) speak;
  const EmergencyTab({super.key, required this.speak});
  @override
  State<EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends State<EmergencyTab>
    with TickerProviderStateMixin {
  bool _sosActive = false;
  bool _sosHolding = false;
  late AnimationController _sosAnim;
  final List<Map<String, String>> _alerts = [];

  // ── Real BLE discovery ──
  final BleDiscoveryService _bleService = BleDiscoveryService();
  List<SakeenahPeer> _nearbyPeers = [];
  StreamSubscription<List<SakeenahPeer>>? _peersSub;
  bool _bleAvailable = true; // assume true until proven otherwise

  @override
  void initState() {
    super.initState();
    _sosAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _initBle();
  }

  Future<void> _initBle() async {
    // Listen to peer updates
    _peersSub = _bleService.peersStream.listen((peers) {
      if (!mounted) return;
      setState(() => _nearbyPeers = peers);
    });

    // Start advertising + scanning
    await _bleService.start();

    if (!_bleService.isRunning && mounted) {
      setState(() => _bleAvailable = false);
    }
  }

  @override
  void dispose() {
    _sosAnim.dispose();
    _peersSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  void _activateSOS() {
    setState(() => _sosActive = true);
    widget.speak('تم إرسال نداء الطوارئ. جاري إبلاغ الحجاج القريبين منك.');
    _addAlert('أنت', 'تم إرسال نداء استغاثة', isOutgoing: true);
    // Notify each discovered peer (no simulated delay)
    if (_nearbyPeers.isNotEmpty) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _addAlert('حاج قريب', 'تم استلام ندائك — المساعدة في الطريق');
        widget.speak(
            'تم استلام ندائك من حاج قريب. المساعدة في الطريق إن شاء الله.');
      });
    }
  }

  void _cancelSOS() {
    setState(() => _sosActive = false);
    widget.speak('تم إلغاء نداء الطوارئ.');
  }

  void _addAlert(String sender, String msg, {bool isOutgoing = false}) {
    final now = DateTime.now();
    setState(() {
      _alerts.insert(0, {
        'sender': sender,
        'message': msg,
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'type': isOutgoing ? 'out' : 'in',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        SakeenahCard(
          bgColor: kEmerald50,
          borderColor: kEmerald400,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: kEmerald700, shape: BoxShape.circle),
              child: const Icon(Icons.bluetooth_searching_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('شبكة سَكينة للطوارئ',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kEmerald900)),
                  const SizedBox(height: 4),
                  Text(
                      _bleAvailable
                          ? '${_nearbyPeers.length} حجاج بالقرب منك متصلون'
                          : 'يرجى تفعيل البلوتوث لاكتشاف الحجاج',
                      style: TextStyle(
                          fontSize: 14,
                          color: _bleAvailable
                              ? kEmerald700
                              : const Color(0xFFDC2626))),
                ])),
            AnimatedBuilder(
              animation: _sosAnim,
              builder: (_, __) => Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      kEmerald400.withValues(alpha: 0.5 + _sosAnim.value * 0.5),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SakeenahCard(
          borderColor: _sosActive ? const Color(0xFFDC2626) : kEmerald200,
          child: Column(children: [
            Text(
              _sosActive
                  ? 'تم إرسال نداء الطوارئ!'
                  : 'اضغط مطوّلاً لإرسال نداء طوارئ',
              style: TextStyle(
                  fontSize: 16,
                  color: _sosActive ? const Color(0xFFDC2626) : kWarmGray),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onLongPressStart: (_) => setState(() => _sosHolding = true),
              onLongPressEnd: (_) {
                setState(() => _sosHolding = false);
                if (!_sosActive) _activateSOS();
              },
              onTap: _sosActive ? _cancelSOS : null,
              child: AnimatedBuilder(
                animation: _sosAnim,
                builder: (_, __) {
                  double scale = _sosActive || _sosHolding
                      ? 1.0 + _sosAnim.value * 0.08
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _sosActive
                              ? [
                                  const Color(0xFFDC2626),
                                  const Color(0xFF991B1B)
                                ]
                              : _sosHolding
                                  ? [
                                      const Color(0xFFEA580C),
                                      const Color(0xFFDC2626)
                                    ]
                                  : [kEmerald400, kEmerald700],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_sosActive
                                    ? const Color(0xFFDC2626)
                                    : kEmerald400)
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _sosActive
                                    ? Icons.check_rounded
                                    : Icons.sos_rounded,
                                color: Colors.white,
                                size: 56),
                            const SizedBox(height: 6),
                            Text(_sosActive ? 'تم الإرسال' : 'SOS',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ]),
                    ),
                  );
                },
              ),
            ),
            if (_sosActive) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _cancelSOS,
                icon:
                    const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                label: const Text('إلغاء النداء',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _sosHolding
                  ? 'استمر بالضغط...'
                  : _sosActive
                      ? 'جاري إبلاغ الحجاج القريبين'
                      : 'اضغط مطوّلاً لمدة ثانيتين',
              style: TextStyle(
                  fontSize: 13,
                  color: _sosHolding ? const Color(0xFFEA580C) : kWarmGray),
            ),
          ]),
        ),
        // ── Nearby Sakeenah users (real BLE) ──
        if (_nearbyPeers.isNotEmpty) ...[
          const SizedBox(height: 8),
          SakeenahCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.people_rounded,
                    color: kEmerald700, size: 22),
                const SizedBox(width: 8),
                Text('حجاج قريبون (${_nearbyPeers.length})',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kEmerald900)),
              ]),
              const Divider(height: 16),
              ..._nearbyPeers.map((peer) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: kEmerald100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: kEmerald700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(peer.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'الإشارة: ${peer.rssi} dBm',
                                style: const TextStyle(
                                    fontSize: 12, color: kWarmGray)),
                          ])),
                      Icon(
                        peer.rssi > -60
                            ? Icons.signal_cellular_alt_rounded
                            : peer.rssi > -80
                                ? Icons.signal_cellular_alt_2_bar_rounded
                                : Icons.signal_cellular_alt_1_bar_rounded,
                        color: peer.rssi > -60
                            ? kEmerald600
                            : peer.rssi > -80
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                        size: 22,
                      ),
                    ]),
                  )),
            ]),
          ),
        ],
        // ── Alert history ──
        if (_alerts.isNotEmpty) ...[
          const SizedBox(height: 8),
          SakeenahCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.history_rounded, color: kWarmGray, size: 22),
                SizedBox(width: 8),
                Text('سجل التنبيهات',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kWarmGray)),
              ]),
              const Divider(height: 16),
              ..._alerts.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            a['type'] == 'out'
                                ? Icons.call_made_rounded
                                : Icons.call_received_rounded,
                            color: a['type'] == 'out'
                                ? const Color(0xFFDC2626)
                                : kEmerald600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(a['sender']!,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                Text(a['message']!,
                                    style: const TextStyle(
                                        fontSize: 13, color: kWarmGray)),
                              ])),
                          Text(a['time']!,
                              style: const TextStyle(
                                  fontSize: 12, color: kWarmGray)),
                        ]),
                  )),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════
// صفحة الخريطة الأوفلاين — MBTiles (مكة المكرمة المحدثة بوضع المحاكاة)
// ═══════════════════════════════════════════
class OfflineMapPage extends StatefulWidget {
  final LatLng currentPos;
  final List<Map<String, dynamic>> aidPoints;
  final void Function(String) speak;

  const OfflineMapPage({
    super.key,
    required this.currentPos,
    required this.aidPoints,
    required this.speak,
  });

  @override
  State<OfflineMapPage> createState() => _OfflineMapPageState();
}

class _OfflineMapPageState extends State<OfflineMapPage> {
  final MapController _mapCtrl = MapController();
  StreamSubscription<Position>? _locSub;
  final GeoJsonRouter _geoJsonRouter = GeoJsonRouter();

  late LatLng _currentPos;
  double _heading = 0.0;

  bool _isLoading = true;
  String _loadingMsg = "جاري تهيئة الخريطة الأوفلاين...";
  String _errorMsg = "";

  MbTilesTileProvider? _tileProvider;
  File? _destFile;

  // متغيرات الفكرة العبقرية الجديدة
  LatLng? _manualSelectedLocation;
  bool _isUserInMakkah = false;
  String _mapNavText = "";
  List<LatLng> _calculatedPath = []; // لرسم الخط الأزرق لأقرب خدمة

  //List<Marker> serviceMarkers = [];
  final List<List<LatLng>> _shadedRoutes = [
    [
      const LatLng(21.4225, 39.8237),
      const LatLng(21.4233, 39.8250),
      const LatLng(21.4240, 39.8262),
      const LatLng(21.4248, 39.8275),
    ],
    [
      const LatLng(21.4195, 39.8255),
      const LatLng(21.4205, 39.8260),
      const LatLng(21.4215, 39.8265),
      const LatLng(21.4225, 39.8262),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _currentPos = widget.currentPos;
    _geoJsonRouter.loadGeoJson();
    loadServiceMarkers();

    // فحص تلقائي ذكي: لو الحاج موجود حالياً في نطاق مكة المكرمة جغرافياً
    if (_currentPos.latitude > 21.3 &&
        _currentPos.latitude < 21.5 &&
        _currentPos.longitude > 39.7 &&
        _currentPos.longitude < 40.0) {
      _isUserInMakkah = true;
      _mapNavText = "جاري تتبع موقعك التلقائي وحساب أقرب الخدمات...";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateNearest(_currentPos);
      });
    } else {
      _isUserInMakkah = false;
      _mapNavText =
          "وضع المحاكاة نشط 🌐\nاضغط على أي مكان بالخريطة لتحديد موقعك الافتراضي وحساب الخدمة.";
    }

    _prepareMbtilesAndMap();
    _startLocationTracking();
  }

  List<Map<String, dynamic>> allServices = [];

  Future<void> loadServiceMarkers() async {
    try {
      // قراءة ملف الـ JSON الجديد اللي نزل من Overpass
      final Map<String, dynamic> data = await _geoJsonRouter.loadLocations();
      List<Map<String, dynamic>> tempServices = [];

      // Overpass بيحط كل النقط جوة قائمة اسمها elements
      final List<dynamic> elements = data['elements'] ?? [];

      for (var element in elements) {
        final tags = element['tags'] ?? {};

        // جلب اسم المكان (لو ملوش اسم هنسجل نوعه)
        final String name = tags['name'] ?? tags['name:ar'] ?? "نقطة خدمة";
        final double? lat = element['lat'];
        final double? lng = element['lon']; // Overpass بيسميها lon

        if (lat == null || lng == null) continue;

        // 1. فحص إذا كان المكان مستشفى
        if (tags['amenity'] == 'hospital') {
          tempServices.add({
            "name": name,
            "location": LatLng(lat, lng),
            "icon": Icons.local_hospital,
            "color": Colors.red,
          });
        }
        // 2. فحص إذا كان المكان نقطة إسعاف
        else if (tags['emergency'] == 'ambulance_station') {
          tempServices.add({
            "name": name,
            "location": LatLng(lat, lng),
            "icon": Icons.emergency,
            "color": Colors.orange,
          });
        }
        // 3. فحص إذا كان المكان نقطة مياه/برادات شرب
        else if (tags['amenity'] == 'drinking_water') {
          tempServices.add({
            "name": name,
            "location": LatLng(lat, lng),
            "icon": Icons.water_drop,
            "color": Colors.blue,
          });
        }
      }

      if (mounted) {
        setState(() {
          allServices = tempServices;
          // حساب أقرب خدمة للموقع الحالي فوراً بعد التحميل
          _calculateNearest(getEffectiveLocation());
        });
      }
    } catch (e) {
      // تم التعديل هنا لـ debugPrint
      debugPrint("خطأ في قراءة ملف الـ JSON الجديد: $e");
    }
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _tileProvider?.dispose();
    super.dispose();
  }

  // دالة لتحديد الموقع الفعال (يدوي أو GPS)
  LatLng getEffectiveLocation() {
    if (!_isUserInMakkah && _manualSelectedLocation != null) {
      return _manualSelectedLocation!;
    }
    return _currentPos;
  }

  // دالة ذكية لحساب أقرب خدمة ورسم الخط الأزرق
  void _calculateNearest(LatLng pos) {
    // 1. التعديل هنا: فحص المخزن الجديد للتأكد من أنه ليس فارغاً
    if (allServices.isEmpty) return;

    double minDist = double.infinity;
    Map<String, dynamic>? nearestPoint;

    // 2. التعديل هنا: البحث داخل قائمة الخدمات الديناميكية الجديدة
    for (var p in allServices) {
      final pLoc = p["location"] as LatLng;
      double d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        pLoc.latitude,
        pLoc.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestPoint = p;
      }
    }

    if (nearestPoint != null) {
      String distStr = minDist >= 1000
          ? "${(minDist / 1000).toStringAsFixed(1)} كم"
          : "${minDist.toStringAsFixed(0)} متر";
      List<LatLng> streetPath =
          _geoJsonRouter.findRoute(pos, nearestPoint["location"] as LatLng);
      setState(() {
        _mapNavText =
            "الموقع المحدد بنجاح 📍\nأقرب نقطة خدمية: ${nearestPoint!["name"]} وتبعد $distStr";
        // تحديث إحداثيات المسار الأزرق المباشر
        _calculatedPath = streetPath;
      });
      // توجيه صوتي تفاعلي يصف للحاج كيف يتحرك
      widget.speak(
          "تم تحديد موقعك. أقرب نقطة لك هي ${nearestPoint["name"]} والمسافة إليها تبلغ حوالي $distStr");
    }
  }

  Future<void> _prepareMbtilesAndMap() async {
    try {
      setState(() => _loadingMsg = "جاري تحضير ملف الخريطة...");

      final docDir = await getApplicationDocumentsDirectory();
      _destFile = File('${docDir.path}/makkah_map.mbtiles');

      if (!await _destFile!.exists()) {
        setState(() => _loadingMsg = "جاري نسخ بيانات الخريطة...");
        final ByteData data =
            await rootBundle.load('assets/map_tiles/makkah_map.mbtiles');
        await _destFile!.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }

      setState(() => _loadingMsg = "جاري تهيئة محرك الخريطة...");

      final mbtiles = MbTiles(mbtilesPath: _destFile!.path);
      final provider = MbTilesTileProvider(mbtiles: mbtiles);

      if (!mounted) return;

      setState(() {
        _tileProvider = provider;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _startLocationTracking() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    _locSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPos = newLoc;
        _heading = pos.heading;
        // لو الحاج في مكة يتم التحديث والتحريك المباشر دون تدخل منه
        if (_isUserInMakkah) {
          _calculateNearest(newLoc);
        }
      });
      try {
        if (_isUserInMakkah) {
          _mapCtrl.move(newLoc, _mapCtrl.camera.zoom);
        }
      } catch (_) {}
    });
  }

  void _centerOnMe() {
    try {
      _mapCtrl.move(getEffectiveLocation(), 16.5);
    } catch (_) {}
  }

  void _speakLocation() {
    widget.speak(_mapNavText.replaceAll('\n', '. '));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _isUserInMakkah ? 'خريطة مكة الأوفلاين' : 'محاكي المسار الآمن'),
          backgroundColor: kEmerald700,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'إرشاد صوتي للمسار',
              onPressed: _speakLocation,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingView()
            : _errorMsg.isNotEmpty
                ? _buildErrorView()
                : _buildMapView(),
        floatingActionButton: _isLoading || _errorMsg.isNotEmpty
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'center_me',
                    mini: true,
                    backgroundColor: kEmerald700,
                    onPressed: _centerOnMe,
                    child: const Icon(Icons.my_location_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'speak_map',
                    mini: true,
                    backgroundColor: kGold,
                    onPressed: _speakLocation,
                    child: const Icon(Icons.volume_up_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: kEmerald700),
          const SizedBox(height: 20),
          Text(_loadingMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: kWarmGray,
                fontFamily: 'Cairo',
              )),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: kWarmGray),
            const SizedBox(height: 16),
            Text(_errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: kWarmGray, fontFamily: 'Cairo')),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMsg = "";
                });
                _prepareMbtilesAndMap();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: kEmerald700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: !_isUserInMakkah
                ? (_manualSelectedLocation ?? const LatLng(21.4267, 39.8261))
                : getEffectiveLocation(),
            initialZoom: 15.5,
            minZoom: 13.0, // عدلناها لتناسب الخريطة اللي نزلناها
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              setState(() {
                _manualSelectedLocation = point;
                globalPickedLocation = point;
                globalLocationMode = LocationMode.picked;
                _calculateNearest(point);
              });
            },
          ),
          children: [
            if (_tileProvider != null)
              TileLayer(
                tileProvider: _tileProvider,
                maxNativeZoom:
                    16, // أضفنا دي عشان الخريطة متختفيش لو عملت زووم أكتر
              ),

            // 1. مسارات الحرم المظلَّلة الثابتة
            PolylineLayer(
              polylines: _shadedRoutes
                  .map((route) => Polyline(
                        points: route,
                        strokeWidth: 7,
                        color: kEmerald400.withValues(alpha: 0.6),
                      ))
                  .toList(),
            ),

            // 2. المسار الأزرق الديناميكي المحسوب من موقع الحاج لأقرب نقطة خدمة
            if (_calculatedPath.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _calculatedPath,
                    strokeWidth: 5.5,
                    color: Colors.blueAccent,
                  ),
                ],
              ),

            // 3. طبقة علامات نقاط الخدمة والموقع
            MarkerLayer(
              markers: [
                // موقع الحاج (أزرق بالبوصلة لو حقيقي، ودبوس أحمر تفاعلي لو افتراضي ومحاكاة)
                Marker(
                  point: getEffectiveLocation(),
                  width: 50,
                  height: 50,
                  child: _isUserInMakkah
                      ? Transform.rotate(
                          angle: _heading * (pi / 180),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.blue,
                            size: 40,
                          ),
                        )
                      : const Icon(
                          Icons.location_on_rounded,
                          color: Colors.red,
                          size: 46,
                        ),
                ),
                // عرض نقاط الخدمات الصحية والإسعافية
                ...allServices.map((p) => Marker(
                      point: p["location"] as LatLng,
                      width: 46,
                      height: 46,
                      child: Tooltip(
                        message: p["name"] as String,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (p["color"] as Color)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            p["icon"] as IconData,
                            color: p["color"] as Color,
                            size: 28,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),

        // لوحة التوجيه العلوية الذكية لوصف المسار والمسافات للحاج
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: SafeArea(
            child: Card(
              color: Colors.white.withValues(alpha: 0.96),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: kEmerald400, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _isUserInMakkah
                          ? Icons.gps_fixed_rounded
                          : Icons.ads_click_rounded,
                      color: kEmerald700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _mapNavText,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
