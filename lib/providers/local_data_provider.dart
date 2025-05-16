import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hive/hive.dart';
import '../models/daily_summary.dart';
import '../models/location.dart';
import '../models/geo_fence.dart';
import '../util/extensions/datetime_extensions.dart';

class LocalDataProvider with ChangeNotifier {
  static final LocalDataProvider _singleton = LocalDataProvider._internal();

  late final Box _localBox;
  late final Box<DailySummary> _dailySummaryBox;

  LocalDataProvider._internal();

  factory LocalDataProvider() => _singleton;

  bool _initialized = false;

  Location? get lastSavedLocation {
    if (!_initialized) return null;
    final lastUpdatedLocation = _localBox.get('lastUpdatedLocation');
    if (lastUpdatedLocation == null) return null;
    return Location.fromJson(lastUpdatedLocation);
  }

  Future<void> init() async {
    final currentDirectory = await path_provider.getApplicationDocumentsDirectory();

    Hive.init(currentDirectory.path);
    _localBox = await Hive.openBox('localData');
    _dailySummaryBox = await Hive.openBox<DailySummary>('daily_summary');
    _initialized = true;
    notifyListeners();
  }

  void updateLastSavedLocation(Location location) {
    _localBox.put('lastUpdatedLocation', location.toJson());
    notifyListeners();
  }

  // Geofence methods
  List<GeoFence> loadGeofences() {
    if (!_initialized) return _getDefaultGeofences();

    final savedGeofences = _localBox.get('geofences');
    List<GeoFence> geofences = [];

    if (savedGeofences != null) {
      try {
        geofences = (savedGeofences as List)
            .map(
              (data) => GeoFence(
                name: data['name'] as String,
                latitude: data['latitude'] as double,
                longitude: data['longitude'] as double,
                radius: (data['radius'] as num?)?.toDouble() ?? 50.0,
              ),
            )
            .toList();
        debugPrint('Loaded ${geofences.length} geofences from storage');
      } catch (e) {
        debugPrint('Error loading geofences: $e');
        geofences = _getDefaultGeofences();
      }
    } else {
      geofences = _getDefaultGeofences();
    }

    saveGeofences(geofences); // Ensure data is saved in the proper format
    return geofences;
  }

  Future<void> saveGeofences(List<GeoFence> geofences) async {
    if (!_initialized) return;

    try {
      final geofencesData = geofences
          .map(
            (fence) => {
              'name': fence.name,
              'latitude': fence.latitude,
              'longitude': fence.longitude,
              'radius': fence.radius,
            },
          )
          .toList();

      log(geofencesData.toString());
      await _localBox.put('geofences', geofencesData);
      debugPrint('Saved ${geofences.length} geofences to storage');
    } catch (e) {
      debugPrint('Error saving geofences: $e');
    }
  }

  List<GeoFence> _getDefaultGeofences() {
    return [
      const GeoFence(name: 'Home', latitude: 37.7749, longitude: -122.4194),
      const GeoFence(name: 'Office', latitude: 37.7858, longitude: -122.4364),
    ];
  }

  // Daily summary methods
  DailySummary loadOrCreateTodaySummary() {
    if (!_initialized) return DailySummary(date: DateTime.now());

    final today = DateTime.now();
    DailySummary summary;

    try {
      summary = _dailySummaryBox.get(today.shortDate) ?? DailySummary(date: today);

      if (_dailySummaryBox.containsKey(today.shortDate)) {
        debugPrint('Loaded daily summary for ${today.shortDate} with ${summary.timePerLocation.length} locations');
        summary.timePerLocation.forEach((location, time) {
          debugPrint('Location: $location, Time: ${Duration(milliseconds: time).inMinutes} minutes');
        });
      } else {
        debugPrint('Created new daily summary for ${today.shortDate}');
      }
    } catch (e) {
      debugPrint('Error loading daily summary: $e');
      summary = DailySummary(date: today);
    }

    return summary;
  }

  Future<void> saveDailySummary(DailySummary summary) async {
    if (!_initialized) return;

    try {
      final date = summary.date.shortDate;
      await _dailySummaryBox.put(date, summary);

      debugPrint('Saved daily summary for $date with ${summary.timePerLocation.length} locations');
    } catch (e) {
      debugPrint('Error saving daily summary: $e');
    }
  }

  void clearHive() {
    Hive.deleteFromDisk();
  }
}
