import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:background_location/background_location.dart' as bg_location;
import '../models/location.dart';
import '../models/geo_fence.dart';
import '../models/daily_summary.dart';
import 'local_data_provider.dart';

class LocationProvider with ChangeNotifier {
  static final LocationProvider _singleton = LocationProvider._internal();

  factory LocationProvider() => _singleton;

  LocationProvider._internal();

  // Location tracking state
  final ValueNotifier<bool> trackingStatus = ValueNotifier<bool>(false);
  DateTime? clockInTime;
  Location? _currentLocation;
  DateTime? _lastLocationUpdateTime;
  DateTime? _lastGeocodingTime;
  bool _hasPermission = false;

  // How often to update geocoding (in minutes)
  static const int _geocodingUpdateInterval = 1;

  // Data providers
  final LocalDataProvider _localDataProvider = LocalDataProvider();

  // Geofence data
  List<GeoFence> _geofences = [];

  // Coordinate threshold for detecting nearby geofences (approximately 10 meters)
  static const double _coordinateThreshold = 0.0001;

  // Today's summary
  DailySummary? _currentDaySummary;

  // Getters
  bool get isTracking => trackingStatus.value;
  bool get hasPermission => _hasPermission;
  Location? get currentLocation => _currentLocation;
  List<GeoFence> get geofences => _geofences;
  DailySummary? get currentDaySummary => _currentDaySummary;

  // Initialize the provider
  Future<void> init() async {
    await _requestPermissions();
    await _loadGeofences();
    await _loadOrCreateTodaySummary();

    if (_hasPermission) {
      await fetchCurrentLocation(forceGeocoding: true);

      // Setup location updates listener regardless of tracking status
      bg_location.BackgroundLocation.getLocationUpdates((location) {
        _updateLocation(location.latitude!, location.longitude!);
      });
    }

    notifyListeners();
  }

  // Ensure background tracking continues to work
  Future<void> ensureBackgroundTracking() async {
    if (!isTracking) return;

    debugPrint('Ensuring background tracking is active');
    // Make sure the location service is running
    await bg_location.BackgroundLocation.startLocationService();
    // Save the current state to ensure no data loss
    saveCurrentState();
  }

  // Save current tracking state to persistent storage
  void saveCurrentState() {
    debugPrint('Saving current tracking state');

    // Update location tracking with latest time
    if (isTracking && _lastLocationUpdateTime != null) {
      _updateTimeTracking();
    }

    // Save daily summary to storage
    _saveDailySummary();

    // Save last known location
    if (_currentLocation != null) {
      _localDataProvider.updateLastSavedLocation(_currentLocation!);
    }
  }

  // Load geofences from storage
  Future<void> _loadGeofences() async {
    _geofences = _localDataProvider.loadGeofences();
  }

  // Save geofences to storage
  Future<void> _saveGeofences() async {
    await _localDataProvider.saveGeofences(_geofences);
  }

  // Request location permissions
  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _hasPermission = permission == LocationPermission.always || permission == LocationPermission.whileInUse;

    // For background location
    await bg_location.BackgroundLocation.startLocationService();
  }

  // Fetch current location
  Future<void> fetchCurrentLocation({bool forceGeocoding = false}) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();
      await _updateLocation(position.latitude, position.longitude, forceGeocoding: forceGeocoding);
    } catch (e) {
      debugPrint('Location fetching failed: $e');
    }
  }

  // Update location from latitude and longitude
  Future<void> _updateLocation(double latitude, double longitude, {bool forceGeocoding = false}) async {
    try {
      final now = DateTime.now();
      final shouldUpdateGeocoding = forceGeocoding ||
          _lastGeocodingTime == null ||
          now.difference(_lastGeocodingTime!).inMinutes >= _geocodingUpdateInterval;

      // Create location with coordinates but no display name yet
      if (_currentLocation == null) {
        _currentLocation = Location(
          country: '',
          displayName: 'Unknown Location',
          latitude: latitude,
          longitude: longitude,
          lastUpdated: now,
        );
      } else {
        // Just update the coordinates
        _currentLocation = Location(
          country: _currentLocation!.country,
          displayName: _currentLocation!.displayName,
          latitude: latitude,
          longitude: longitude,
          lastUpdated: now,
        );
      }

      // Only perform geocoding if needed
      if (shouldUpdateGeocoding) {
        _updateLocationDisplayName(latitude, longitude);
      }

      // Update time tracking if currently tracking
      if (isTracking) {
        _updateTimeTracking();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update location: $e');
    }
  }

  // Update location display name with geocoding (separate method to reduce API calls)
  Future<void> _updateLocationDisplayName(double latitude, double longitude) async {
    try {
      final List<geocoding.Placemark> placeMarks = await geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placeMarks.isEmpty) return;

      final placemark = placeMarks[0];

      if (_currentLocation != null) {
        _currentLocation = Location(
          country: placemark.country ?? '',
          displayName: placemark.locality ?? placemark.name ?? 'Unknown Location',
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          lastUpdated: _currentLocation!.lastUpdated,
        );

        _lastGeocodingTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }
  }

  // Load or create today's summary
  Future<void> _loadOrCreateTodaySummary() async {
    _currentDaySummary = _localDataProvider.loadOrCreateTodaySummary();
  }

  // Start tracking location
  Future<void> clockIn() async {
    if (isTracking) return;

    clockInTime = DateTime.now();
    _lastLocationUpdateTime = DateTime.now();
    trackingStatus.value = true;

    // Make sure background location service is running
    await bg_location.BackgroundLocation.startLocationService();

    notifyListeners();
  }

  // Stop tracking location
  Future<void> clockOut() async {
    if (!isTracking) return;

    // Update one last time before stopping
    if (_lastLocationUpdateTime != null) {
      _updateTimeTracking();
    }

    trackingStatus.value = false;
    clockInTime = null;

    // Don't stop background service, just stop tracking the time
    // We still want location updates when not tracking

    // Save current summary to storage
    _saveDailySummary();

    notifyListeners();
  }

  // Update time tracking based on current location
  void _updateTimeTracking() {
    if (_currentLocation == null || _lastLocationUpdateTime == null) return;

    // Ensure we have a current day summary
    _currentDaySummary ??= DailySummary(date: DateTime.now());

    final now = DateTime.now();
    final timeDelta = now.difference(_lastLocationUpdateTime!).inMilliseconds;

    // Check if inside any geofence
    bool insideAnyFence = false;
    String? matchedGeofence;

    for (final fence in _geofences) {
      if (fence.isInside(_currentLocation!)) {
        _currentDaySummary!.addTimeToLocation(fence.name, timeDelta);
        insideAnyFence = true;
        matchedGeofence = fence.name;
        break; // Stop after finding the first matching geofence
      }
    }

    // If not inside any fence, add to traveling time
    if (!insideAnyFence) {
      _currentDaySummary!.addTravelingTime(timeDelta);
      debugPrint('Added $timeDelta ms to traveling time');
    } else if (matchedGeofence != null) {
      debugPrint('Added $timeDelta ms to location "$matchedGeofence"');
    }

    _lastLocationUpdateTime = now;

    // Save summary after each update to ensure data is persisted
    _saveDailySummary();

    notifyListeners();
  }

  // Save the daily summary to storage
  void _saveDailySummary() {
    if (_currentDaySummary == null) return;
    _localDataProvider.saveDailySummary(_currentDaySummary!);
  }

  // Check if a geofence with the given name already exists
  bool hasGeofenceWithName(String name) {
    return _geofences.any((fence) => fence.name.toLowerCase() == name.toLowerCase());
  }

  // Check if a geofence at the given coordinates already exists
  bool hasGeofenceAtLocation(double latitude, double longitude) {
    return _geofences.any(
      (fence) =>
          (fence.latitude - latitude).abs() < _coordinateThreshold &&
          (fence.longitude - longitude).abs() < _coordinateThreshold,
    );
  }

  // Validate geofence before adding (returns error message or null if valid)
  String? validateGeofence(String name, double latitude, double longitude) {
    if (name.isEmpty) {
      return 'Please enter a name for the geo-fence';
    }

    if (hasGeofenceWithName(name)) {
      return 'A geo-fence named "$name" already exists';
    }

    if (hasGeofenceAtLocation(latitude, longitude)) {
      return 'A geo-fence already exists at this location';
    }

    return null; // No validation errors
  }

  // Add a custom geofence if validation passes
  String? addGeofence(String name, double latitude, double longitude, {double radius = 50}) {
    final validationError = validateGeofence(name, latitude, longitude);
    if (validationError != null) {
      return validationError;
    }

    _geofences.add(
      GeoFence(
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      ),
    );
    _saveGeofences();
    notifyListeners();
    return null; // Success
  }
}
