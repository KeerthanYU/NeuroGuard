import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase might already be initialized in this isolate context
  }

  final riskStr = message.data['risk_score'] ?? message.data['risk'];
  final double risk = double.tryParse(riskStr?.toString() ?? '') ?? 0.0;
  final bool isSeizure = message.data['type'] == 'seizure' || risk > 80.0;

  if (isSeizure) {
    await NotificationService().showEmergencyAlert(
      title: message.notification?.title ?? '🚨 CRITICAL SEIZURE ALERT',
      body: message.notification?.body ?? 'A seizure or high risk has been detected! Immediate attention required.',
    );
  }
}

/// Handles all push and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ─── Initialize ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // FCM setup
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Register background/terminated handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen(_handleFcmMessage);

    // Handle notification clicks when the app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }

    // Create notification channels (Android)
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Alerts',
      description: 'Critical seizure detection alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const healthChannel = AndroidNotificationChannel(
      'health_channel',
      'Health Monitoring',
      description: 'Heart rate and motion alerts',
      importance: Importance.high,
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(healthChannel);
  }

  // ─── Show Emergency Alert ─────────────────────────────────────────────────
  Future<void> showEmergencyAlert({
    required String title,
    required String body,
    int id = 9001,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical seizure alerts',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'SEIZURE DETECTED',
      fullScreenIntent: true,
      color: Color(0xFFFF1744),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifs.show(id, title, body, details);
  }

  // ─── Show Health Alert ────────────────────────────────────────────────────
  Future<void> showHealthAlert({
    required String title,
    required String body,
    int id = 9002,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'health_channel',
      'Health Monitoring',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF00D4FF),
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifs.show(id, title, body, details);
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────
  Future<void> cancelAll() async => await _localNotifs.cancelAll();

  void _onNotificationTap(NotificationResponse response) {
    // Navigate to emergency screen or handle custom response
  }

  void _handleFcmMessage(RemoteMessage message) {
    final riskStr = message.data['risk_score'] ?? message.data['risk'];
    final double risk = double.tryParse(riskStr?.toString() ?? '') ?? 0.0;

    if (message.data['type'] == 'seizure' || risk > 80.0) {
      showEmergencyAlert(
        title: message.notification?.title ?? '🚨 CRITICAL SEIZURE DETECTED',
        body: message.notification?.body ?? 'Immediate attention required!',
      );
    } else {
      showHealthAlert(
        title: message.notification?.title ?? 'Vitals Warning',
        body: message.notification?.body ?? 'Elevated physiological measurements registered.',
      );
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    // Can propagate events to Riverpod/Navigator to route directly to emergency details
  }

  Future<String?> getFcmToken() async => await _fcm.getToken();
}
