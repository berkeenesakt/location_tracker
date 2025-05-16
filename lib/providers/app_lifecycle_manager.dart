import 'package:flutter/material.dart';
import 'location_provider.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  final LocationProvider _locationProvider;

  AppLifecycleManager(this._locationProvider) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and running in foreground
        debugPrint('App resumed - synchronizing location data');
        _locationProvider.fetchCurrentLocation(forceGeocoding: true);
        break;

      case AppLifecycleState.paused:
        // App is not visible but still running in background
        debugPrint('App paused - ensuring background tracking is active');
        if (_locationProvider.isTracking) {
          // Make sure background location tracking is active
          _locationProvider.ensureBackgroundTracking();
        }
        break;

      case AppLifecycleState.detached:
        // App is terminated
        debugPrint('App detached');
        if (_locationProvider.isTracking) {
          // Save current state before app is terminated
          _locationProvider.saveCurrentState();
        }
        break;

      case AppLifecycleState.inactive:
        // App is in an inactive state (e.g., during a phone call)
        debugPrint('App inactive');
        break;

      case AppLifecycleState.hidden:
        // App is hidden but still active
        debugPrint('App hidden');
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
