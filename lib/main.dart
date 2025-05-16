import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/daily_summary.dart';
import 'models/geo_fence.dart';
import 'models/location.dart';
import 'providers/location_provider.dart';
import 'providers/local_data_provider.dart';
import 'providers/home_provider.dart';
import 'providers/app_lifecycle_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'gen/fonts.gen.dart';
import 'gen/colors.gen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDependencies().then((_) => runApp(MyApp()));
}

Future<void> initializeDependencies() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(DailySummaryAdapter());
  Hive.registerAdapter(GeoFenceAdapter());
  updateLocalTimeZone();
}

Future<void> updateLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifecycleManager _lifecycleManager;
  late LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    _locationProvider = LocationProvider();
    _lifecycleManager = AppLifecycleManager(_locationProvider);
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<LocalDataProvider>(create: (_) => LocalDataProvider()),
        ChangeNotifierProvider<LocationProvider>.value(value: _locationProvider),
      ],
      child: MaterialApp(
        title: 'Example project',
        navigatorKey: widget.navigatorKey,
        debugShowCheckedModeBanner: false,
        scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        theme: ThemeData(
          primaryColor: Colors.black,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.white,
            secondary: const Color(0xFF131F34),
            tertiary: const Color(0xFF667085),
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.all(const Color(0xFF131F34)),
          ),
          canvasColor: Colors.white,
          fontFamily: Fonts.sFPro,
          scaffoldBackgroundColor: Colors.white,
          dividerTheme: const DividerThemeData(color: Color(0xFFEAECF0), space: 0),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF005b96)),
          ),
          textTheme: const TextTheme(
            titleMedium: TextStyle(fontWeight: FontWeight.w600, height: 1.1, fontSize: 22, letterSpacing: 0.4),
            titleSmall: TextStyle(fontWeight: FontWeight.w600, height: 1.1, fontSize: 16, letterSpacing: 0.24),
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, height: 1.15, letterSpacing: 0.4),
            bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, height: 1.15, letterSpacing: 0.4),
          ),
          tabBarTheme: TabBarTheme(
            indicatorSize: TabBarIndicatorSize.tab,
            unselectedLabelColor: Colors.grey.shade300,
            labelColor: Colors.black,
            splashFactory: NoSplash.splashFactory,
            labelPadding: const EdgeInsets.only(bottom: 1),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected) ? AppColors.secondary : AppColors.lightGrey;
            }),
            checkColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
