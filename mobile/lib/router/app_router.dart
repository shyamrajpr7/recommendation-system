import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/search_screen.dart';
import '../screens/recommendation_detail_screen.dart';
import '../screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const SearchScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/recommendation/:index',
        builder: (_, state) {
          final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
          return RecommendationDetailScreen(index: index);
        },
      ),
    ],
  );
});
