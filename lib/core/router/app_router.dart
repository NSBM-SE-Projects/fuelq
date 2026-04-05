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
import '../../features/station_attendant/screens/station_attendant_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final user = ref.read(userProvider).valueOrNull;
      final currentPath = state.uri.path;

      const publicRoutes = [
        '/splash',
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
        '/station-attendant',
      ];

      const registrationRoutes = ['/add-vehicle', '/register'];

      final isPublicRoute = publicRoutes.contains(currentPath);
      final isRegistrationRoute = registrationRoutes.contains(currentPath);

      if (currentPath == '/splash') return null;

      if (!isLoggedIn && !isPublicRoute) {
        return '/welcome';
      }

      if (isLoggedIn &&
          isPublicRoute &&
          currentPath != '/splash' &&
          currentPath != '/station-attendant' &&
          !isRegistrationRoute) {
        return user?.role.name == 'stationAttendant'
            ? '/station-attendant'
            : '/home';
      }

      if (isLoggedIn &&
          user?.role.name == 'stationAttendant' &&
          currentPath == '/home') {
        return '/station-attendant';
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
        path: '/station-attendant',
        builder: (context, state) => const StationAttendantScreen(),
      ),
    ],
  );
});

class _RouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<User?>> _authSub;
  late final ProviderSubscription<AsyncValue<dynamic>> _userSub;

  _RouterRefreshStream(Ref ref) {
    _authSub = ref.listen(authStateProvider, (_, _) => notifyListeners());
    _userSub = ref.listen(userProvider, (_, _) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub.close();
    _userSub.close();
    super.dispose();
  }
}
