import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/now_showing_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/showtime_screen.dart';
import '../screens/seat_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/ai_search_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/my_booking_screen.dart';
import '../screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(
        path: '/detail/:movieId',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '0') ?? 0;
          return DetailScreen(movieId: id);
        },
      ),
      ShellRoute(
        builder: (_, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const NowShowingScreen()),
          GoRoute(path: '/search', builder: (_, _) => const AiSearchScreen()),
          GoRoute(path: '/chat', builder: (_, _) => const AiChatScreen()),
          GoRoute(path: '/bookings', builder: (_, _) => const MyBookingScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/showtimes/:movieId', builder: (_, state) {
        final id = int.tryParse(state.pathParameters['movieId'] ?? '0') ?? 0;
        return ShowtimeScreen(movieId: id);
      }),
      GoRoute(path: '/seats/:showtimeId', builder: (_, state) {
        final id = int.tryParse(state.pathParameters['showtimeId'] ?? '0') ?? 0;
        return SeatScreen(showtimeId: id);
      }),
      GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
    ],
  );
});
