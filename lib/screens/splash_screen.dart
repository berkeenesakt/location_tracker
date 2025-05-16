import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:after_layout/after_layout.dart';
import '../models/location.dart';
import 'dashboard_screen.dart';
import '../providers/location_provider.dart';
import '../providers/local_data_provider.dart';
import '../gen/colors.gen.dart';
import '../gen/assets.gen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  }

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with AfterLayoutMixin<SplashScreen> {
  @override
  void afterFirstLayout(BuildContext context) => _initializeApp();

  final LocalDataProvider localDataProvider = LocalDataProvider();

  Future<void> _initializeApp() async {
    await _initializeAppServices();
    _redirectToDashboard();
  }

  Future<void> _initializeAppServices() async {
    await Future.wait([
      localDataProvider.init(),
    ]);

    Future.wait([
      updateLocation(),
    ]);
  }

  Future<void> updateLocation() async {
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.init();

    final Location? currentLocation = locationProvider.currentLocation;
    final Location? lastSavedLocation = localDataProvider.lastSavedLocation;

    if (currentLocation != null && lastSavedLocation == null) {
    } else if (currentLocation != null && lastSavedLocation != null) {
      final distanceInKm = currentLocation.distanceTo(lastSavedLocation);
      if (distanceInKm > 10) {
        localDataProvider.updateLastSavedLocation(currentLocation);
      }
    }
  }

  void _redirectToDashboard() {
    Navigator.pushReplacement(context, Dashboard.route());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          alignment: Alignment.center,
          child: Assets.logoText.svg(
            width: 240,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
