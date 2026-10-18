import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gym_managment_app/core/constants/app_constants.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_skeleton_theme.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/theme/app_theme.dart';

class GymApp extends StatefulWidget {
  final GoRouter? router;

  const GymApp({super.key, this.router});

  static void restartApp(BuildContext context, {String? snackBarMessage}) {
    final state = context.findAncestorStateOfType<_GymAppState>();
    if (state != null) {
      state.restart(snackBarMessage: snackBarMessage);
    } else {
      if (context.mounted) {
        try {
          context.go(AppRoutes.dashboard);
        } catch (_) {}
        if (snackBarMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      snackBarMessage,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  @override
  State<GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<GymApp> {
  Key _key = UniqueKey();
  late GoRouter _currentRouter;
  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _currentRouter = widget.router ?? appRouter;
  }

  void restart({String? snackBarMessage}) {
    setState(() {
      _key = UniqueKey();
      try {
        _currentRouter.dispose();
      } catch (_) {}
      appRouter = createAppRouter();
      _currentRouter = appRouter;
      _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    });

    if (snackBarMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    snackBarMessage,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    if (widget.router == null) {
      try {
        _currentRouter.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
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
        routerConfig: _currentRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return SkeletonizerConfig(
            data: AppSkeletonTheme.config,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
