import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../models/station_model.dart';
import '../providers/station_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:custom_info_window/custom_info_window.dart';

// Default centre = Colombo
const _defaultLocation = LatLng(6.884587, 79.902008);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const String _mapStyle = '''
  [
    {
      "featureType": "road",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';

  GoogleMapController? _mapController;
  StationModel? _selectedStation;
  final CustomInfoWindowController _infoWindowController = CustomInfoWindowController();

  BitmapDescriptor greenMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor yellowMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  BitmapDescriptor redMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _moveToUserLocation();
  }

  @override
  void dispose() {
    _infoWindowController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    greenMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/markers/green.png'
    );
    yellowMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/markers/yellow.png'
    );
    redMarker = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/markers/red.png'
    );
    setState(() {});
  }

  Future<void> _moveToUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
    );
  }

  Set<Marker> _buildMarkers(List<StationModel> stations) {
    return stations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: station.location,
        icon: _markerIcon(station),
        onTap: () {
          _infoWindowController.addInfoWindow!(
            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _availabilityColor(station),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      station.availabilityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _availabilityColor(station)
                      ),
                    ),
                  ],
                ),
                Text(
                  '${station.currentQueue}/${station.maxQueue}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
          station.location,
    );
        setState(() => _selectedStation = station);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(station.location.latitude - 0.02, station.location.longitude),
          ),
        );
        },
      );
    }).toSet();
  }

 BitmapDescriptor _markerIcon(StationModel station) {
    if (!station.isOpen) return redMarker;
    switch (station.availability) {
      case StationAvailability.available: return greenMarker;
      case StationAvailability.busy: return yellowMarker;
      case StationAvailability.full:
      case StationAvailability.closed: return redMarker;
    }
  }

  Color _availabilityColor(StationModel station) {
    if (!station.isOpen) return AppColors.error;
    switch (station.availability) {
      case StationAvailability.available: return AppColors.success;
      case StationAvailability.busy: return AppColors.warning;
      case StationAvailability.full:
      case StationAvailability.closed: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    return Scaffold(
      body: stationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stations) {
          final markers = _buildMarkers(stations);
          return Stack(
            children: [
              GoogleMap(
                style: _mapStyle,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                initialCameraPosition: const CameraPosition(
                  target: _defaultLocation,
                  zoom: 12,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _infoWindowController.googleMapController = controller;
                  _moveToUserLocation();
                },
                onCameraMove: (position) {
                  _infoWindowController.onCameraMove!();
                },
                onTap: (_) {
                  _infoWindowController.hideInfoWindow!();
                  setState(() => _selectedStation = null);
                },
              ),

              CustomInfoWindow(
                controller: _infoWindowController,
                height: 90,
                width: 200,
                offset: 40,
              ),

              // Back button + title
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                            child: const Text(
                              'Fuel Stations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _MapButton(
                          icon: Icons.my_location_rounded,
                          onTap: _moveToUserLocation,
                        ),
                      ],
                    ),
                  ),

                  // Legend
                  Positioned(
                    bottom: _selectedStation != null ? 315:32,
                    left: 16,
                    child: _Legend(),
                  ),

                  // Station bottom sheet
                  if (_selectedStation != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _StationSheet(
                      station: _selectedStation!,
                      availabilityColor: _availabilityColor(_selectedStation!),
                      onClose: () => setState(() => _selectedStation = null),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }


}

Color _fuelTypeColor(StationFuelType type) {
    switch (type) {
      case StationFuelType.petrol92: return Colors.amber;
      case StationFuelType.petrol95: return Colors.red;
      case StationFuelType.diesel: return Colors.green;
      case StationFuelType.superDiesel: return Colors.black;
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({ required this.icon, required this.onTap });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: AppColors.success, label: 'Available'),
          SizedBox(width: 12),
          _LegendDot(color: AppColors.warning, label: 'Busy'),
          SizedBox(width: 12),
          _LegendDot(color: AppColors.error, label: 'Full'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({ required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StationSheet extends StatelessWidget {
  final StationModel station;
  final Color availabilityColor;
  final VoidCallback onClose;

  const _StationSheet({
    required this.station,
    required this.availabilityColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4),)
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            station.address,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Availability Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: availabilityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: availabilityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      station.availabilityLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: availabilityColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Fuel types chips
              ...station.fuelTypes.map((type) {
                final color = _fuelTypeColor(type);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      StationModel.fuelTypeLabel(type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                  ),
                ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${station.location.latitude},${station.location.longitude}',
                );
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Get Directions'),
            )
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/book-station', extra: station),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Book Slot'),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _InfoTile(
                icon: Icons.people_rounded,
                label: 'Queue',
                value: '${station.currentQueue} / ${station.maxQueue}',
              ),
              const SizedBox(width: 12),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'Hours',
                value: '${station.openTime} - ${station.closeTime}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}