import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> scheduleSubscriptionExpiry({
    required int subscriptionId,
    required String memberName,
    required DateTime endDate,
    int daysBefore = 3,
  });
  Future<void> cancelSubscriptionExpiry(int subscriptionId);
  Future<void> showExpiringGroupNotification({required int count});
  Future<void> cancelAll();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'subscription_expiry_channel';
  static const String channelName = 'تنبيهات انتهاء الاشتراكات';
  static const String channelDescription =
      'تنبيهات لاقتراب موعد انتهاء اشتراك المشتركين';

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          developer.log('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e, stack) {
      developer.log(
        'Failed to initialize NotificationService: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted =
            await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      developer.log('Failed to request notification permission: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleSubscriptionExpiry({
    required int subscriptionId,
    required String memberName,
    required DateTime endDate,
    int daysBefore = 3,
  }) async {
    try {
      if (!_isInitialized) await init();

      final scheduledDate = endDate.subtract(Duration(days: daysBefore));
      final scheduledTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        10,
        0,
      );

      if (scheduledTime.isBefore(DateTime.now())) {
        return;
      }

      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        id: subscriptionId,
        title: 'تنبيه انتهاء الاشتراك',
        body: 'اشتراك المشترك $memberName ينتهي خلال $daysBefore أيام',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: 'member_subscription:$subscriptionId',
      );
    } catch (e, stack) {
      developer.log(
        'Error scheduling subscription notification: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> cancelSubscriptionExpiry(int subscriptionId) async {
    try {
      await _notificationsPlugin.cancel(id: subscriptionId);
    } catch (e) {
      developer.log('Error cancelling subscription notification: $e');
    }
  }

  @override
  Future<void> showExpiringGroupNotification({required int count}) async {
    if (count <= 0) return;
    try {
      if (!_isInitialized) await init();

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: 999999,
        title: 'تنبيه الاشتراكات',
        body: 'يوجد $count اشتراكات تنتهي قريباً',
        notificationDetails: notificationDetails,
        payload: 'expiring_members',
      );
    } catch (e, stack) {
      developer.log(
        'Error showing group notification: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      developer.log('Error cancelling all notifications: $e');
    }
  }
}
