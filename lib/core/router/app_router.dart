import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Imports des écrans (squelettes pour l'instant)
import '../../features/today/today_screen.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

/// Routes nommées
class AppRoutes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const plan = '/plan';
  static const progress = '/progress';
  static const profile = '/profile';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.today,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithBottomNav(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const PlanScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.today,
            builder: (context, state) => const TodayScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.progress,
            builder: (context, state) => const ProgressScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);

class _ScaffoldWithBottomNav extends StatelessWidget {
  const _ScaffoldWithBottomNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_outlined),
            activeIcon: Icon(Icons.water),
            label: "Aujourd'hui",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Progression',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Moi',
          ),
        ],
      ),
    );
  }
}
