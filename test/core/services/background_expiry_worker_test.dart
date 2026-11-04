import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/constants/app_constants.dart';
import 'package:gym_managment_app/core/database/daos/dashboard_dao.dart';
import 'package:gym_managment_app/core/services/background_expiry_worker.dart';
import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardDao extends Mock implements DashboardDao {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDashboardDao mockDashboardDao;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockDashboardDao = MockDashboardDao();
    mockNotificationService = MockNotificationService();

    when(() => mockNotificationService.init()).thenAnswer((_) async {});
    when(() => mockNotificationService.showSubscriptionExpiringNotification(
          subscriptionId: any(named: 'subscriptionId'),
          memberName: any(named: 'memberName'),
          daysLeft: any(named: 'daysLeft'),
        )).thenAnswer((_) async {});
    when(() => mockNotificationService.showExpiringGroupNotification(
          count: any(named: 'count'),
        )).thenAnswer((_) async {});
  });

  group('BackgroundExpiryWorker', () {
    test('returns true without notifications when no expiring members exist', () async {
      when(() => mockDashboardDao.getExpiringSubscriptions(
            now: any(named: 'now'),
            windowDays: AppConstants.expiringSoonDays,
          )).thenAnswer((_) async => []);

      final result = await BackgroundExpiryWorker.execute(
        dashboardDao: mockDashboardDao,
        notificationService: mockNotificationService,
      );

      expect(result, isTrue);
      verify(() => mockNotificationService.init()).called(1);
      verifyNever(() => mockNotificationService.showSubscriptionExpiringNotification(
            subscriptionId: any(named: 'subscriptionId'),
            memberName: any(named: 'memberName'),
            daysLeft: any(named: 'daysLeft'),
          ));
      verifyNever(() => mockNotificationService.showExpiringGroupNotification(
            count: any(named: 'count'),
          ));
    });

    test('shows individual notification for single expiring member and no group notification', () async {
      final expiringRow = ExpiringSubscriptionRow(
        memberId: 101,
        memberName: 'أحمد علي',
        phone: '01012345678',
        endDate: DateTime.now().add(const Duration(days: 2)),
        daysLeft: 2,
        packageName: 'اشتراك شهري',
      );

      when(() => mockDashboardDao.getExpiringSubscriptions(
            now: any(named: 'now'),
            windowDays: AppConstants.expiringSoonDays,
          )).thenAnswer((_) async => [expiringRow]);

      final result = await BackgroundExpiryWorker.execute(
        dashboardDao: mockDashboardDao,
        notificationService: mockNotificationService,
      );

      expect(result, isTrue);
      verify(() => mockNotificationService.showSubscriptionExpiringNotification(
            subscriptionId: 101,
            memberName: 'أحمد علي',
            daysLeft: 2,
          )).called(1);
      verifyNever(() => mockNotificationService.showExpiringGroupNotification(
            count: any(named: 'count'),
          ));
    });

    test('shows individual and group notifications for multiple expiring members', () async {
      final rows = [
        ExpiringSubscriptionRow(
          memberId: 101,
          memberName: 'أحمد علي',
          phone: '01012345678',
          endDate: DateTime.now().add(const Duration(days: 1)),
          daysLeft: 1,
        ),
        ExpiringSubscriptionRow(
          memberId: 102,
          memberName: 'محمد حسام',
          phone: '01098765432',
          endDate: DateTime.now().add(const Duration(days: 3)),
          daysLeft: 3,
        ),
      ];

      when(() => mockDashboardDao.getExpiringSubscriptions(
            now: any(named: 'now'),
            windowDays: AppConstants.expiringSoonDays,
          )).thenAnswer((_) async => rows);

      final result = await BackgroundExpiryWorker.execute(
        dashboardDao: mockDashboardDao,
        notificationService: mockNotificationService,
      );

      expect(result, isTrue);
      verify(() => mockNotificationService.showSubscriptionExpiringNotification(
            subscriptionId: 101,
            memberName: 'أحمد علي',
            daysLeft: 1,
          )).called(1);
      verify(() => mockNotificationService.showSubscriptionExpiringNotification(
            subscriptionId: 102,
            memberName: 'محمد حسام',
            daysLeft: 3,
          )).called(1);
      verify(() => mockNotificationService.showExpiringGroupNotification(
            count: 2,
          )).called(1);
    });

    test('returns false when an error occurs during execution', () async {
      when(() => mockDashboardDao.getExpiringSubscriptions(
            now: any(named: 'now'),
            windowDays: AppConstants.expiringSoonDays,
          )).thenThrow(Exception('Database disk I/O error'));

      final result = await BackgroundExpiryWorker.execute(
        dashboardDao: mockDashboardDao,
        notificationService: mockNotificationService,
      );

      expect(result, isFalse);
    });
  });
}
