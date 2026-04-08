import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/vehicle_registration_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/dashboard/screens/quota_dashboard_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/analytics/screens/admin_dashboard_screen.dart';
import '../../features/analytics/screens/national_analytics_screen.dart';
import '../../features/analytics/screens/station_analytics_screen.dart';
import '../../features/analytics/screens/regional_view_screen.dart';
import '../../features/analytics/screens/user_insights_screen.dart';
import '../../features/analytics/screens/quota_forecasting_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final currentPath = state.uri.path;

      // Public routes that don't require auth
      const publicRoutes = [
        '/splash',
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
      ];

      // Routes that are part of registration flow
      const registrationRoutes = ['/add-vehicle', '/register'];

      final isPublicRoute = publicRoutes.contains(currentPath);
      final isRegistrationRoute = registrationRoutes.contains(currentPath);

      // Don't redirect if on splash (it handles its own navigation)
      if (currentPath == '/splash') return null;

      // Not logged in trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return '/welcome';
      }

      // Logged in trying to access auth screens (welcome/login/register)
      if (isLoggedIn &&
          isPublicRoute &&
          currentPath != '/splash' &&
          !isRegistrationRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/add-vehicle',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return VehicleRegistrationScreen(
            uid: data['uid'] as String,
            isFirstTime: data['isFirstTime'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/quota',
        builder: (context, state) => const QuotaDashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/analytics/national',
        builder: (context, state) => const NationalAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/stations',
        builder: (context, state) => const StationAnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/regional',
        builder: (context, state) => const RegionalViewScreen(),
      ),
      GoRoute(
        path: '/analytics/users',
        builder: (context, state) => const UserInsightsScreen(),
      ),
      GoRoute(
        path: '/analytics/quota',
        builder: (context, state) => const QuotaForecastingScreen(),
      ),
    ],
  );
});

/// Notifies GoRouter when auth state changes so redirect re-evaluates.
class _RouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<User?>> _subscription;

// Changed to (_, __) again due to avoiding naming conflicts, keeping to standard.
  _RouterRefreshStream(Ref ref) {
    _subscription = ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
