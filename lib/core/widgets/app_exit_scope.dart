import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../router/routes.dart';
import 'exit_confirmation_dialog.dart';

/// Intercepts back navigation gestures / buttons.
///
/// When [Navigator.canPop] is true and no [onWillPop] guard blocks it,
/// allows the system to pop the route naturally back to the previous screen.
///
/// When [Navigator.canPop] is false (meaning the user is about to leave/exit the app):
/// - If [fallbackToDashboard] is true, redirects back to Dashboard.
/// - If [fallbackToDashboard] is false, displays [showExitConfirmationDialog]
///   and exits the app via [SystemNavigator.pop] if confirmed.
class AppExitScope extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onWillPop;
  final bool fallbackToDashboard;

  const AppExitScope({
    super.key,
    required this.child,
    this.onWillPop,
    this.fallbackToDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: onWillPop == null ? canPop : false,
      onPopInvokedWithResult: (didPop, result) async {
        FocusManager.instance.primaryFocus?.unfocus();
        if (didPop) return;

        if (onWillPop != null) {
          final allow = await onWillPop!();
          if (!allow) return;
          if (!context.mounted) return;
          if (canPop) {
            Navigator.of(context).pop();
            return;
          }
        }

        if (!context.mounted) return;

        if (fallbackToDashboard) {
          context.go(AppRoutes.dashboard);
          return;
        }

        final shouldExit = await showExitConfirmationDialog(context);
        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
