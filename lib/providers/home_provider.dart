import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/summary_screen.dart';

enum AppScreen {
  HOME,
  SUMMARY,
}

class HomeProvider with ChangeNotifier {
  final _screens = [
    const HomeScreen(),
    const SummaryScreen(),
  ];

  int _currentIndex = 0;

  Future<void> switchToIndex(int index) async {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> switchToScreen(AppScreen screen) async {
    _currentIndex = AppScreen.values.indexOf(screen);
    notifyListeners();
  }

  void reset() {
    _currentIndex = AppScreen.HOME.index;
    notifyListeners();
  }

  int get currentIndex => _currentIndex;

  Widget get selectedScreen => _screens.elementAt(_currentIndex);
}
