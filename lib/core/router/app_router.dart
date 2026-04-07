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
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/qr/screens/qr_display_screen.dart';
import '../../features/qr/screens/qr_scanner_screen.dart';
import '../../features/dashboard/screens/quota_dashboard_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/models/station_model.dart';
import '../../features/booking/screens/station_booking_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/booking/models/booking_model.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../constants/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final user = ref.read(userProvider).valueOrNull;
      final currentPath = state.uri.path;
      final isAttendant = user?.role == UserRole.stationAttendant;

      const publicRoutes = ['/splash', '/welcome', '/login', '/register', '/forgot-password'];
      const registrationRoutes = ['/add-vehicle', '/register'];

      final isPublicRoute = publicRoutes.contains(currentPath);
      final isRegistrationRoute = registrationRoutes.contains(currentPath);

      if (currentPath == '/splash') return null;
      if (!isLoggedIn && !isPublicRoute) return '/welcome';
      if (isLoggedIn && isPublicRoute && currentPath != '/splash' && !isRegistrationRoute) {
        return isAttendant ? '/station-attendant' : '/home';
      }
      if (isLoggedIn && isAttendant && currentPath == '/home') return '/station-attendant';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/add-vehicle',
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return VehicleRegistrationScreen(
            uid: data['uid'] as String,
            isFirstTime: data['isFirstTime'] as bool? ?? false,
          );
        },
      ),

      // Main app with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, state) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/my-bookings', builder: (_, state) => const MyBookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, state) => const ProfileScreen()),
          ]),
        ],
      ),

      // Screens that push on top of the nav bar
      GoRoute(path: '/quota', builder: (_, state) => const QuotaDashboardScreen()),
      GoRoute(
        path: '/book-station',
        builder: (_, state) {
          final station = state.extra as StationModel;
          return StationBookingScreen(station: station);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return PaymentScreen(
            stationId: data['stationId'] as String,
            stationName: data['stationName'] as String,
            vehicleId: data['vehicleId'] as String,
            vehicleNumber: data['vehicleNumber'] as String,
            fuelType: data['fuelType'] as String,
            slotStart: data['slotStart'] as DateTime,
            litresBooked: data['litresBooked'] as double? ?? 0.0,
          );
        },
      ),
      GoRoute(
        path: '/booking-confirmed',
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return BookingConfirmationScreen(
            booking: data['booking'] as BookingModel,
            slotDuration: data['slotDuration'] as Duration,
          );
        },
      ),
      GoRoute(
        path: '/booking-detail',
        builder: (_, state) {
          final booking = state.extra as BookingModel;
          return BookingDetailScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/qr-display',
        builder: (context, state) => const QrDisplayScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/station-attendant',
        builder: (context, state) => const QrScannerScreen(),
      ),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

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
