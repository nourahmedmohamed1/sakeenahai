import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // زودي السطر ده فوق

// 1. تصنيف أنواع الخدمات المتاحة
enum ServiceType {
  hospital, // مستشفى أو إسعاف
  water, // نقطة مياه
  coolingZone // خيمة مبردة أو شارع مظلل
}

// 2. نموذج مكان الخدمة
class ServiceLocation {
  final String id;
  final String name;
  final LatLng position;
  final ServiceType type;

  ServiceLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
  });
}

// 3. كود البحث عن الأقرب (ضيفيه هنا في النهاية)
class SmartAdvisor {
  // قاعدة البيانات الأوفلاين لكل الخدمات في مكة
  final List<ServiceLocation> allServices = [
    ServiceLocation(
        id: "h1",
        name: "مستشفى أجياد الدولي",
        position: LatLng(21.4195, 39.8262),
        type: ServiceType.hospital),
    ServiceLocation(
        id: "h2",
        name: "مركز إسعاف الحرم",
        position: LatLng(21.4220, 39.8250),
        type: ServiceType.hospital),
    ServiceLocation(
        id: "w1",
        name: "نقطة مياه زمزم 1",
        position: LatLng(21.4230, 39.8270),
        type: ServiceType.water),
    ServiceLocation(
        id: "c1",
        name: "خيمة مبردة بمنى",
        position: LatLng(21.4180, 39.8290),
        type: ServiceType.coolingZone),
  ];

  // الدالة اللي بتحدد أقرب مكان تلقائياً بناءً على موقع الحاج ونوع الخدمة
  ServiceLocation findNearestService(
      LatLng userLocation, ServiceType requestedType) {
    ServiceLocation? nearestPlace;
    double shortestDistance = double.infinity;

    for (var place in allServices) {
      if (place.type == requestedType) {
        // حساب المسافة بالمتر بين الحاج والمكان الحالي
        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          place.position.latitude,
          place.position.longitude,
        );

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestPlace = place;
        }
      }
    }

    return nearestPlace!;
  }
}
