import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../models/vehicle_model.dart';
import '../providers/auth_provider.dart';

class VehicleRegistrationScreen extends ConsumerStatefulWidget {
  final String uid;
  final bool isFirstTime;

  const VehicleRegistrationScreen({
    super.key,
    required this.uid,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState
    extends ConsumerState<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _nicknameController = TextEditingController();
  FuelType _selectedFuelType = FuelType.petrol;
  bool _isLoading = false;

  final List<VehicleModel> _addedVehicles = [];

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _chassisNumberController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vehicle = VehicleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
        chassisNumber: _chassisNumberController.text.trim().toUpperCase(),
        fuelType: _selectedFuelType,
        nickname: _nicknameController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref
          .read(authServiceProvider)
          .addVehicle(uid: widget.uid, vehicle: vehicle);

      setState(() {
        _addedVehicles.add(vehicle);
        _vehicleNumberController.clear();
        _chassisNumberController.clear();
        _nicknameController.clear();
        _selectedFuelType = FuelType.petrol;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
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

  void _finish() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 28,
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
                if (!widget.isFirstTime)
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                if (!widget.isFirstTime) const SizedBox(height: 16),
                if (widget.isFirstTime) const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstTime
                                ? 'Register Your Vehicle'
                                : 'Add New Vehicle',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isFirstTime
                                ? 'Add at least one vehicle to get started'
                                : 'Add another vehicle to your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_addedVehicles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_addedVehicles.length} added',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_addedVehicles.isNotEmpty) ...[
                    Text(
                      'REGISTERED VEHICLES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._addedVehicles.map((v) => _VehicleCard(vehicle: v)),
                    const SizedBox(height: 24),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('VEHICLE NUMBER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _vehicleNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CAB-1234',
                            prefixIcon: Icon(
                              Icons.directions_car_outlined,
                              color: AppColors.primarySoft,
                            ),
                          ),
                          validator: Validators.vehicleNumber,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('CHASSIS NUMBER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _chassisNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Enter chassis number',
                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                              color: AppColors.primarySoft,
                            ),
                          ),
                          validator: Validators.chassisNumber,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('VEHICLE NICKNAME (OPTIONAL)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nicknameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Toyota Prius',
                            prefixIcon: Icon(
                              Icons.label_outlined,
                              color: AppColors.primarySoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('FUEL TYPE'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _FuelTypeChip(
                                label: 'Petrol',
                                icon: Icons.local_gas_station,
                                isSelected:
                                    _selectedFuelType == FuelType.petrol,
                                onTap: () => setState(
                                  () => _selectedFuelType = FuelType.petrol,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FuelTypeChip(
                                label: 'Diesel',
                                icon: Icons.local_gas_station_outlined,
                                isSelected:
                                    _selectedFuelType == FuelType.diesel,
                                onTap: () => setState(
                                  () => _selectedFuelType = FuelType.diesel,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _addVehicle,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_rounded),
                                    const SizedBox(width: 8),
                                    Text(
                                      _addedVehicles.isEmpty
                                          ? 'Add Vehicle'
                                          : 'Add Another Vehicle',
                                    ),
                                  ],
                                ),
                        ),
                        if (widget.isFirstTime &&
                            _addedVehicles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _finish,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Continue to Dashboard'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ],
                        if (!widget.isFirstTime) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _addVehicle,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Save Vehicle'),
                                SizedBox(width: 8),
                                Icon(Icons.check_rounded, size: 20),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.nickname.isNotEmpty
                      ? vehicle.nickname
                      : vehicle.vehicleNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.vehicleNumber} \u00B7 ${vehicle.fuelType.name[0].toUpperCase()}${vehicle.fuelType.name.substring(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _FuelTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FuelTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
