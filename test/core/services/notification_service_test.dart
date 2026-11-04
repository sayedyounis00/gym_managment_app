import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationServiceImpl service;

  setUpAll(() {
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const InitializationSettings());
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationServiceImpl(plugin: mockPlugin);

    when(() => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        )).thenAnswer((_) async => true);

    when(() => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});

    when(() => mockPlugin.cancel(
          id: any(named: 'id'),
          tag: any(named: 'tag'),
        )).thenAnswer((_) async {});

    when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});
  });

  group('NotificationService', () {
    test('showSubscriptionExpiringNotification formats text for expiring today (0 days left)', () async {
      await service.showSubscriptionExpiringNotification(
        subscriptionId: 42,
        memberName: 'سيد يونس',
        daysLeft: 0,
      );

      verify(() => mockPlugin.show(
            id: 42,
            title: 'تنبيه انتهاء الاشتراك',
            body: 'اشتراك المشترك سيد يونس ينتهي اليوم!',
            notificationDetails: any(named: 'notificationDetails'),
            payload: 'member_subscription:42',
          )).called(1);
    });

    test('showSubscriptionExpiringNotification formats text for expiring tomorrow (1 day left)', () async {
      await service.showSubscriptionExpiringNotification(
        subscriptionId: 43,
        memberName: 'محمود',
        daysLeft: 1,
      );

      verify(() => mockPlugin.show(
            id: 43,
            title: 'تنبيه انتهاء الاشتراك',
            body: 'اشتراك المشترك محمود ينتهي غداً',
            notificationDetails: any(named: 'notificationDetails'),
            payload: 'member_subscription:43',
          )).called(1);
    });

    test('showSubscriptionExpiringNotification formats text for expiring in 2 days', () async {
      await service.showSubscriptionExpiringNotification(
        subscriptionId: 44,
        memberName: 'علي',
        daysLeft: 2,
      );

      verify(() => mockPlugin.show(
            id: 44,
            title: 'تنبيه انتهاء الاشتراك',
            body: 'اشتراك المشترك علي ينتهي خلال يومين',
            notificationDetails: any(named: 'notificationDetails'),
            payload: 'member_subscription:44',
          )).called(1);
    });

    test('showSubscriptionExpiringNotification formats text for expiring in 5 days', () async {
      await service.showSubscriptionExpiringNotification(
        subscriptionId: 45,
        memberName: 'سارة',
        daysLeft: 5,
      );

      verify(() => mockPlugin.show(
            id: 45,
            title: 'تنبيه انتهاء الاشتراك',
            body: 'اشتراك المشترك سارة ينتهي خلال 5 أيام',
            notificationDetails: any(named: 'notificationDetails'),
            payload: 'member_subscription:45',
          )).called(1);
    });

    test('showExpiringGroupNotification displays count summary notification', () async {
      await service.showExpiringGroupNotification(count: 7);

      verify(() => mockPlugin.show(
            id: 999999,
            title: 'تنبيه الاشتراكات',
            body: 'يوجد 7 اشتراكات تنتهي قريباً',
            notificationDetails: any(named: 'notificationDetails'),
            payload: 'expiring_members',
          )).called(1);
    });

    test('showExpiringGroupNotification ignores count <= 0', () async {
      await service.showExpiringGroupNotification(count: 0);
      verifyNever(() => mockPlugin.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ));
    });

    test('cancelSubscriptionExpiry calls plugin cancel with subscription id', () async {
      await service.cancelSubscriptionExpiry(123);
      verify(() => mockPlugin.cancel(id: 123)).called(1);
    });

    test('cancelAll calls plugin cancelAll', () async {
      await service.cancelAll();
      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });
}
