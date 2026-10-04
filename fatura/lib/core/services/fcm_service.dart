/// fcm_service.dart — Firebase Cloud Messaging setup for sync notifications
///
/// - Background handler for sync notifications
/// - Topic subscription per store
/// - Notification: "فيه بيانات جاهزة للمزامنة"
///
/// Paper Ledger design: notifications use Arabic-first text.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level function.
/// Called when a sync notification arrives and the app is terminated.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 FCM background: ${message.notification?.title} — ${message.data}');

  // Show a local notification so the user sees it even if app is killed.
  final flutterLocalNotifications = FlutterLocalNotificationsPlugin();
  await flutterLocalNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final title = message.notification?.title ?? 'فاتورة';
  final body = message.notification?.body ?? 'فيه بيانات جاهزة للمزامنة';

  await flutterLocalNotifications.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fatura_sync_channel',
        'مزامنة فاتورة',
        channelDescription: 'إشعارات المزامنة بين الأجهزة',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

/// FCM Service — manages Firebase Cloud Messaging lifecycle.
///
/// Usage:
///   await FcmService.instance.initialize();
///   await FcmService.instance.subscribeToStore('store_123');
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  String? _currentStoreTopic;

  /// Initialize FCM + local notifications.
  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();

    // Set background handler.
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    // Request permission (iOS — Android grants by default).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // Init local notifications (for foreground display).
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Create Android channel for sync notifications.
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'fatura_sync_channel',
            'مزامنة فاتورة',
            description: 'إشعارات المزامنة بين الأجهزة',
            importance: Importance.high,
          ));
    }

    // Get FCM token.
    _fcmToken = await _fcm.getToken();
    debugPrint('🔔 FCM token: $_fcmToken');

    // Listen to foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen to token refresh.
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('🔔 FCM token refreshed: $token');
    });

    _initialized = true;
  }

  /// Get the current FCM token (null if not initialized).
  String? get token => _fcmToken;

  /// Subscribe to a store-specific topic for sync notifications.
  Future<void> subscribeToStore(String storeId) async {
    final topic = 'store_$storeId';
    if (_currentStoreTopic != null && _currentStoreTopic != topic) {
      await _fcm.unsubscribeFromTopic(_currentStoreTopic!);
    }
    await _fcm.subscribeToTopic(topic);
    _currentStoreTopic = topic;
    debugPrint('🔔 Subscribed to store topic: $topic');
  }

  /// Unsubscribe from current store topic.
  Future<void> unsubscribeFromStore() async {
    if (_currentStoreTopic != null) {
      await _fcm.unsubscribeFromTopic(_currentStoreTopic!);
      debugPrint('🔔 Unsubscribed from: $_currentStoreTopic');
      _currentStoreTopic = null;
    }
  }

  /// Handle foreground sync notification.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 FCM foreground: ${message.notification?.title}');

    final title = message.notification?.title ?? 'فاتورة';
    final body = message.notification?.body ?? 'فيه بيانات جاهزة للمزامنة';

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fatura_sync_channel',
          'مزامنة فاتورة',
          channelDescription: 'إشعارات المزامنة بين الأجهزة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Dispose — unsubscribe from all topics.
  Future<void> dispose() async {
    await unsubscribeFromStore();
  }
}