import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/today/today_screen.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

/// Routes nommées
class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const plan = '/plan';
  static const progress = '/progress';
  static const profile = '/profile';
}

// ── RouterNotifier ────────────────────────────────────────────────────────────
// Écoute authProvider et notifie go_router pour déclencher un re-redirect.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }
  final Ref _ref;
}

// ── Provider GoRouter ─────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.today,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLoading = auth.status == AuthStatus.unknown;
      final isAuthenticated = auth.status == AuthStatus.authenticated;
      final onWelcome = state.matchedLocation == AppRoutes.welcome;

      // Tant que l'état auth n'est pas encore connu, ne pas rediriger
      if (isLoading) return null;

      // Non authentifié → welcome
      if (!isAuthenticated && !onWelcome) return AppRoutes.welcome;

      // Déjà authentifié et sur /welcome → today
      if (isAuthenticated && onWelcome) return AppRoutes.today;

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── App shell (tabs) ──────────────────────────────────────────────────
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
});

// ── Bottom nav shell ──────────────────────────────────────────────────────────

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
