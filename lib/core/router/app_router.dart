import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/vehicle_registration_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/dashboard/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
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
      path: '/',
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
      path: '/role-selection',
      builder: (context, state) {
        final userData = state.extra as Map<String, String>;
        return RoleSelectionScreen(userData: userData);
      },
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
