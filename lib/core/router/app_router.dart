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
import '../../features/auth/models/user_model.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/models/station_model.dart';
import '../../features/booking/screens/station_booking_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/booking/models/booking_model.dart';
import '../../features/station_attendant/screens/station_attendant_screen.dart';
import '../../features/station_attendant/screens/qr_scanner_screen.dart' as attendant_qr;
import '../../features/station_attendant/screens/vehicle_lookup_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/analytics/screens/admin_dashboard_screen.dart';
import '../../features/analytics/screens/national_analytics_screen.dart';
import '../../features/analytics/screens/station_analytics_screen.dart';
import '../../features/analytics/screens/regional_view_screen.dart';
import '../../features/analytics/screens/user_insights_screen.dart';
import '../../features/analytics/screens/quota_forecasting_screen.dart';
import '../constants/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final currentPath = state.uri.path;

      const publicRoutes = ['/splash', '/welcome', '/login', '/register', '/forgot-password'];
      const registrationRoutes = ['/add-vehicle', '/register'];

      final isPublicRoute = publicRoutes.contains(currentPath);
      final isRegistrationRoute = registrationRoutes.contains(currentPath);

      // Attendant-only routes
      const attendantRoutes = ['/station-attendant', '/attendant-profile', '/attendant-qr-scanner', '/vehicle-lookup'];
      const adminRoutes = ['/admin', '/analytics/national', '/analytics/stations', '/analytics/regional', '/analytics/users', '/analytics/quota'];

      if (currentPath == '/splash') return null;
      if (!isLoggedIn && !isPublicRoute) return '/welcome';
      if (isLoggedIn && isPublicRoute && currentPath != '/splash' && !isRegistrationRoute) {
        final user = ref.read(userProvider).valueOrNull;
        if (user == null) return null; // User data not loaded yet — let the screen handle navigation
        if (user.role == UserRole.stationAttendant) return '/station-attendant';
        if (user.role == UserRole.governmentAdmin) return '/admin';
        return '/home';
      }

      // Role guard: redirect non-attendants away from attendant routes
      if (isLoggedIn && attendantRoutes.contains(currentPath)) {
        final user = ref.read(userProvider).valueOrNull;
        if (user != null && user.role != UserRole.stationAttendant) {
          return '/home';
        }
      }

      if (isLoggedIn && adminRoutes.contains(currentPath)) {
        final user = ref.read(userProvider).valueOrNull;
        if (user != null && user.role != UserRole.governmentAdmin) {
          return '/home';
        }
      }

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
      // Station attendant with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AttendantShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/station-attendant', builder: (_, state) => const StationAttendantScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/attendant-qr-scanner', builder: (_, state) => const attendant_qr.QrScannerScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/attendant-profile', builder: (_, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/vehicle-lookup', builder: (_, state) => const VehicleLookupScreen()),

      GoRoute(path: '/admin', builder: (_, state) => const AdminDashboardScreen()),
      GoRoute(path: '/analytics/national', builder: (_, state) => const NationalAnalyticsScreen()),
      GoRoute(path: '/analytics/stations', builder: (_, state) => const StationAnalyticsScreen()),
      GoRoute(path: '/analytics/regional', builder: (_, state) => const RegionalViewScreen()),
      GoRoute(path: '/analytics/users', builder: (_, state) => const UserInsightsScreen()),
      GoRoute(path: '/analytics/quota', builder: (_, state) => const QuotaForecastingScreen()),
      GoRoute(path: '/admin-profile', builder: (_, state) => const ProfileScreen()),
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

class _AttendantShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AttendantShell({required this.navigationShell});

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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            label: 'QR',
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
  late final ProviderSubscription<AsyncValue<User?>> _subscription;

  _RouterRefreshStream(Ref ref) {
    _subscription = ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
