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
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

/// Notifies GoRouter when auth state changes so redirect re-evaluates.
class _RouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<User?>> _subscription;

  _RouterRefreshStream(Ref ref) {
    _subscription = ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
