import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gym_managment_app/core/constants/app_constants.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/theme/app_skeleton_theme.dart';
import 'package:gym_managment_app/core/theme/app_theme.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: null,
      themeMode: ThemeMode.light,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return SkeletonizerConfig(
          data: AppSkeletonTheme.config,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
