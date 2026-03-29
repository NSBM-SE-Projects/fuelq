import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, String> userData;

  const RoleSelectionScreen({super.key, required this.userData});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _continue() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      final user = UserModel(
        uid: widget.userData['uid']!,
        name: widget.userData['name']!,
        email: widget.userData['email']!,
        phone: widget.userData['phone']!,
        nic: widget.userData['nic']!,
        role: _selectedRole!,
        createdAt: DateTime.now(),
      );

      await ref.read(authServiceProvider).saveUserData(user);

      if (mounted) {
        if (_selectedRole == UserRole.vehicleOwner) {
          context.go('/add-vehicle',
              extra: {'uid': user.uid, 'isFirstTime': true});
        } else {
          context.go('/home');
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you will use FuelPass LK',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Role cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  _RoleCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Vehicle Owner',
                    description:
                        'Register vehicles, book fuel slots, and manage your weekly quota.',
                    isSelected: _selectedRole == UserRole.vehicleOwner,
                    onTap: () =>
                        setState(() => _selectedRole = UserRole.vehicleOwner),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.local_gas_station_rounded,
                    title: 'Station Attendant',
                    description:
                        'Manage station bookings, scan QR codes, and handle fuel dispensing.',
                    isSelected: _selectedRole == UserRole.stationAttendant,
                    onTap: () => setState(
                        () => _selectedRole = UserRole.stationAttendant),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Government Admin',
                    description:
                        'View analytics, manage quotas, and monitor fuel distribution.',
                    isSelected: _selectedRole == UserRole.governmentAdmin,
                    onTap: () => setState(
                        () => _selectedRole = UserRole.governmentAdmin),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _selectedRole != null && !_isLoading
                        ? _continue
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Continue'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      )
                    : null,
                color: isSelected
                    ? null
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primaryLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
