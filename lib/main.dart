import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';

import 'package:gym_managment_app/core/services/notification_service.dart';
import 'package:gym_managment_app/core/services/background_backup_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap image cache to prevent memory bloat on mobile devices
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024;

  await initializeDateFormatting('ar', null);
  Intl.defaultLocale = 'ar';

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  try {
    await initDependencies();
    await Future.wait([
      sl<NotificationService>().init(),
      BackgroundBackupWorker.init(),
    ]);
    await sl<NotificationService>().requestPermission();
  } catch (error, stackTrace) {
    developer.log('Initialization error', error: error, stackTrace: stackTrace);
  }

  runApp(const GymApp());
}
