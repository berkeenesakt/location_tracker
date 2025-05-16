import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'location.dart';

part 'geo_fence.g.dart';

@HiveType(typeId: 2)
class GeoFence {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final double radius; // in meters

  const GeoFence({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 50, // Default 50m radius
  });

  bool isInside(Location location) {
    // Calculate distance between location and geofence center
    final distanceInMeters = Geolocator.distanceBetween(latitude, longitude, location.latitude, location.longitude);

    return distanceInMeters <= radius;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  factory GeoFence.fromJson(Map<String, dynamic> json) {
    return GeoFence(
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      radius: json['radius'] as double,
    );
  }
}
