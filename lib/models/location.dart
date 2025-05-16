import 'dart:math';
import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 0)
class Location {
  @HiveField(0)
  final String country;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final DateTime lastUpdated;

  Location({
    required this.country,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      country: json['country'] as String,
      displayName: json['displayName'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  num distanceTo(Location other) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers
    final double dLat = (other.latitude - latitude) * (3.141592653589793 / 180);
    final double dLon = (other.longitude - longitude) * (3.141592653589793 / 180);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(latitude * (3.141592653589793 / 180)) *
            cos(other.latitude * (3.141592653589793 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  String toString() {
    return 'Location{country: $country, displayName: $displayName, latitude: $latitude, longitude: $longitude}';
  }
}

class GoogleLocation {
  final String description;
  final String placeId;

  GoogleLocation({required this.description, required this.placeId});

  factory GoogleLocation.fromJson(Map<String, dynamic> json) {
    return GoogleLocation(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}
