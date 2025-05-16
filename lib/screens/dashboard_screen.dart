import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../animations/fade_animation.dart';
import '../../components/glass_container.dart';
import '../../providers/home_provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => const Dashboard(), fullscreenDialog: true);
  }

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final activeIconColor = Colors.white;
  late final iconColor = Colors.white54;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Consumer<HomeProvider>(
        builder: (_, homeProvider, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.fastOutSlowIn,
              child: homeProvider.selectedScreen,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
            floatingActionButton: FadeAnimation(
              duration: 0.4,
              visible: !keyboardOpen,
              child: GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                borderRadius: BorderRadius.circular(30),
                padding: EdgeInsets.zero,
                child: BottomNavigationBar(
                  elevation: 0,
                  selectedFontSize: 0,
                  unselectedFontSize: 0,
                  backgroundColor: Colors.transparent,
                  fixedColor: Colors.white,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: homeProvider.currentIndex,
                  onTap: homeProvider.switchToIndex,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home, color: iconColor, size: 24),
                      activeIcon: GlowingIcon(child: Icon(Icons.home, color: activeIconColor, size: 24)),
                      label: 'Main',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics, color: iconColor, size: 24),
                      activeIcon: GlowingIcon(child: Icon(Icons.analytics, color: activeIconColor, size: 24)),
                      label: 'Summary',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GlowingIcon extends StatelessWidget {
  final Widget child;

  const GlowingIcon({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
