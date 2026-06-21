import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // للـ debugPrint
import 'package:latlong2/latlong.dart';

// المكتبة دي فيها كلاس Distance و LengthUnit
class GeoJsonRouter {
  // بناء الـ Graph: كل نقطة (Node) ترتبط بقائمة من النقاط المجاورة (Edges)
  Map<String, Set<String>> adjacencyList = {};
  Map<String, LatLng> nodeCoordinates = {};

  String _makeKey(LatLng pt) {
    return "${pt.latitude.toStringAsFixed(5)},${pt.longitude.toStringAsFixed(5)}";
  }

  Future<void> loadGeoJson() async {
    try {
      String data =
          await rootBundle.loadString('assets/routing/makkah_streets.geojson');
      Map<String, dynamic> jsonMap = jsonDecode(data);
      var features = jsonMap['features'] as List;

      adjacencyList.clear();
      nodeCoordinates.clear();

      for (var feature in features) {
        var geometry = feature['geometry'];
        if (geometry['type'] == 'LineString') {
          var coordinates = geometry['coordinates'] as List;
          List<LatLng> points = [];

          for (var coord in coordinates) {
            points.add(LatLng(
              double.parse(coord[1].toString()),
              double.parse(coord[0].toString()),
            ));
          }

          // بناء الشبكة المبدئية للشوارع المتصلة
          for (int i = 0; i < points.length - 1; i++) {
            String key1 = _makeKey(points[i]);
            String key2 = _makeKey(points[i + 1]);

            nodeCoordinates[key1] = points[i];
            nodeCoordinates[key2] = points[i + 1];

            adjacencyList.putIfAbsent(key1, () => <String>{});
            adjacencyList.putIfAbsent(key2, () => <String>{});

            adjacencyList[key1]!.add(key2);
            adjacencyList[key2]!.add(key1);
          }
        }
      }

      // ---------- عبقرية الربط (Graph Healing) ----------
      // اللوب ده بيلف يربط أي تقاطعين المسافة بينهم أقل من 25 متر
      // عشان الشوارع المنفصلة تتلحم والـ Dijkstra ينجح يمشي جواها!
      List<String> keys = nodeCoordinates.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        for (int j = i + 1; j < keys.length; j++) {
          if (_calculateRealDistance(
                  nodeCoordinates[keys[i]]!, nodeCoordinates[keys[j]]!) <
              0.00000005) {
            adjacencyList[keys[i]]!.add(keys[j]);
            adjacencyList[keys[j]]!.add(keys[i]);
          }
        }
      }
      // -------------------------------------------------

      debugPrint(
          "تم بناء شبكة الشوارع بنجاح أوفلاين! إجمالي التقاطعات: ${nodeCoordinates.length}");
    } catch (e) {
      debugPrint("خطأ في قراءة ملف الشوارع: $e");
    }
  }

  Future<Map<String, dynamic>> loadLocations() async {
    try {
      String data = await rootBundle.loadString('assets/locations.json');
      return jsonDecode(data);
    } catch (e) {
      debugPrint("خطأ في تحميل مواقع الخدمات: $e");
      // التعديل هنا: إرجاع elements فاضية لتناسب الهيكل الجديد
      return {"elements": []};
    }
  }

  List<LatLng> findRoute(LatLng start, LatLng end) {
    if (nodeCoordinates.isEmpty) return [start, end];

    String startNode = _getNearestNode(start);
    String endNode = _getNearestNode(end);

    if (startNode == endNode) return [start, end];

    List<String> pathIds = _runDijkstra(startNode, endNode);

    // لو الخوارزمية فشلت إنها تلاقي شارع يوصلهم، ارسم خط مستقيم مباشر ونظيف
    // بدلاً من رسم المسار المثلثي العشوائي
    if (pathIds.isEmpty || pathIds.first != startNode) {
      return [start, end];
    }

    List<LatLng> fullPath = [start];
    for (String id in pathIds) {
      fullPath.add(nodeCoordinates[id]!);
    }
    fullPath.add(end);

    return fullPath;
  }

  String _getNearestNode(LatLng target) {
    String nearest = "";
    double minDist = double.infinity;

    nodeCoordinates.forEach((key, coord) {
      double dist = _calculateRealDistance(target, coord);
      if (dist < minDist) {
        minDist = dist;
        nearest = key;
      }
    });
    return nearest;
  }

  List<String> _runDijkstra(String startId, String endId) {
    Set<String> unvisited = Set.from(nodeCoordinates.keys);
    Map<String, double> distances = {};
    Map<String, String> previous = {};

    for (var key in nodeCoordinates.keys) {
      distances[key] = double.infinity;
    }
    distances[startId] = 0.0;

    while (unvisited.isNotEmpty) {
      String current = "";
      double minD = double.infinity;
      for (var node in unvisited) {
        if (distances[node]! < minD) {
          minD = distances[node]!;
          current = node;
        }
      }

      if (current == "" || current == endId) break;

      unvisited.remove(current);

      for (var neighbor in adjacencyList[current] ?? <String>{}) {
        if (unvisited.contains(neighbor)) {
          double alt = distances[current]! +
              _calculateRealDistance(
                  nodeCoordinates[current]!, nodeCoordinates[neighbor]!);
          if (alt < distances[neighbor]!) {
            distances[neighbor] = alt;
            previous[neighbor] = current;
          }
        }
      }
    }

    List<String> path = [];
    String? curr = endId;
    while (curr != null) {
      path.insert(0, curr);
      if (curr == startId) break;
      curr = previous[curr];
    }

    return path;
  }

  // حساب المسافة التربيعية (أسرع وأخف على معالج الموبايل)
  double _calculateRealDistance(LatLng p1, LatLng p2) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2).toDouble();
  }
}
