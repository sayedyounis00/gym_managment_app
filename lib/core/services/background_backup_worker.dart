import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/settings/data/datasources/backup_source.dart';
import '../di/injection_container.dart';
import 'background_expiry_worker.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'weekly_auto_backup') {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        await initDependencies();
        final backupSource = sl<BackupSource>();
        await backupSource.createBackup(share: false);
      } catch (e) {
        debugPrint('Workmanager weekly auto-backup failed: $e');
      }
    } else if (task == BackgroundExpiryWorker.taskIdentifier) {
      return await BackgroundExpiryWorker.execute();
    }
    return Future.value(true);
  });
}

abstract final class BackgroundBackupWorker {
  static Future<void> init() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      await Workmanager().registerPeriodicTask(
        'weekly_auto_backup_task',
        'weekly_auto_backup',
        frequency: const Duration(days: 7),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      await BackgroundExpiryWorker.registerPeriodicTask();
    } catch (e) {
      debugPrint('BackgroundBackupWorker initialization failed: $e');
    }
  }
}
