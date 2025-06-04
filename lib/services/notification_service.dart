import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Create watering reminder channel
        const AndroidNotificationChannel wateringChannel =
            AndroidNotificationChannel(
              'watering_reminder',
              'Watering Reminder',
              description: 'Notifications for watering reminders',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            );

        await androidImplementation.createNotificationChannel(wateringChannel);

        // Create payment success channel
        const AndroidNotificationChannel paymentChannel =
            AndroidNotificationChannel(
              'payment_success',
              'Payment Success',
              description: 'Notifications for successful payments',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            );

        await androidImplementation.createNotificationChannel(paymentChannel);

        // Create order status channel
        const AndroidNotificationChannel orderChannel =
            AndroidNotificationChannel(
              'order_status',
              'Order Status',
              description: 'Notifications for order status updates',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            );

        await androidImplementation.createNotificationChannel(orderChannel);
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showPaymentSuccessNotification({
    required String plantName,
    required String totalAmount,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'payment_success',
          'Payment Success',
          channelDescription: 'Notifications for successful payments',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50), // Green color
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0, // notification id
      '🎉 Pembayaran Berhasil!',
      'Pesanan $plantName ($totalAmount) telah diproses. Terima kasih telah berbelanja di TPM Flora!',
      details,
      payload: 'payment_success',
    );
  }

  Future<void> showOrderStatusNotification({
    required String title,
    required String message,
    int? notificationId,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_status',
          'Order Status',
          channelDescription: 'Notifications for order status updates',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF2196F3), // Blue color
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId ?? 1,
      title,
      message,
      details,
      payload: 'order_status',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> scheduleWateringReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'watering_reminder',
          'Watering Reminder',
          channelDescription: 'Notifications for watering reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50),
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showWateringNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'watering_reminder',
          'Watering Reminder',
          channelDescription: 'Notifications for watering reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50),
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Use a fixed ID for immediate watering notifications
      title,
      body,
      details,
    );
  }
}
