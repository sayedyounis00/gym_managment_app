import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import '../database/daos/dashboard_dao.dart';
import '../di/injection_container.dart';
import 'notification_service.dart';

abstract final class BackgroundExpiryWorker {
  static const String taskIdentifier = 'check_expiring_subscriptions';
  static const String periodicTaskName = 'check_expiring_subscriptions_task';

  static Future<bool> execute({
    DashboardDao? dashboardDao,
    NotificationService? notificationService,
    DateTime? now,
  }) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      if (dashboardDao == null || notificationService == null) {
        await initDependencies();
      }

      final dao = dashboardDao ?? sl<DashboardDao>();
      final notif = notificationService ?? sl<NotificationService>();

      await notif.init();

      final currentDate = now ?? DateTime.now();
      final expiringRows = await dao.getExpiringSubscriptions(
        now: currentDate,
        windowDays: AppConstants.expiringSoonDays,
      );

      if (expiringRows.isEmpty) {
        return true;
      }

      for (final row in expiringRows) {
        await notif.showSubscriptionExpiringNotification(
          subscriptionId: row.memberId,
          memberName: row.memberName,
          daysLeft: row.daysLeft,
        );
      }

      if (expiringRows.length > 1) {
        await notif.showExpiringGroupNotification(count: expiringRows.length);
      }

      return true;
    } catch (e, stack) {
      debugPrint('BackgroundExpiryWorker failed: $e\n$stack');
      return false;
    }
  }

  static Future<void> registerPeriodicTask({
    Workmanager? workmanager,
  }) async {
    try {
      final wm = workmanager ?? Workmanager();
      await wm.registerPeriodicTask(
        periodicTaskName,
        taskIdentifier,
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('BackgroundExpiryWorker registration failed: $e');
    }
  }
}
