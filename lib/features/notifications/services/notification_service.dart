import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> showVehicleNearbyNotification({
    required String vehicleNumber,
    required String ownerName,
    required double distanceMetres,
  }) async {
    await init();
    final androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Vehicle Arrivals',
      channelDescription:
          'Alerts when a booked vehicle enters the station zone',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      color: const Color(0xFF1B3A5C),
    );
    await _plugin.show(
      vehicleNumber.hashCode,
      '🚗 Vehicle Nearby — $vehicleNumber',
      '$ownerName is ${distanceMetres.toStringAsFixed(0)}m from the station',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
