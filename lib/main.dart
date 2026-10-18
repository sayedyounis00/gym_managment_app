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
    await sl<NotificationService>().init();
    await BackgroundBackupWorker.init();
  } catch (error, stackTrace) {
    developer.log('Initialization error', error: error, stackTrace: stackTrace);
  }

  runApp(const GymApp());
}
