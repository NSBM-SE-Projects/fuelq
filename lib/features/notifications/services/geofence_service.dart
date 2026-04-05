import 'dart:async';
import 'package:geolocator/geolocator.dart';

const double kStationLat = 6.9147;
const double kStationLng = 79.8560;

class GeofenceService {
  GeofenceService._();
  static final GeofenceService instance = GeofenceService._();

  StreamSubscription<Position>? _positionSub;
  final _alertController = StreamController<double>.broadcast();
  final _distanceController = StreamController<double?>.broadcast();

  Stream<double> get onGeofenceEntered => _alertController.stream;

  Stream<double?> get distanceStream => _distanceController.stream;

  bool _wasInside = false;
  double _currentRadius = 100.0;

  Future<bool> requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startMonitoring({double radius = 100.0}) async {
    _currentRadius = radius;
    stopMonitoring();

    final granted = await requestPermissions();
    if (!granted) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
  }

  void updateRadius(double radius) {
    _currentRadius = radius;
    _wasInside = false;
  }

  void _onPosition(Position position) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      kStationLat,
      kStationLng,
    );

    _distanceController.add(distance);

    final isInside = distance <= _currentRadius;
    if (isInside && !_wasInside) {
      _alertController.add(distance);
    }
    _wasInside = isInside;
  }

  void stopMonitoring() {
    _positionSub?.cancel();
    _positionSub = null;
    _wasInside = false;
    _distanceController.add(null);
  }

  void dispose() {
    stopMonitoring();
    _alertController.close();
    _distanceController.close();
  }
}
