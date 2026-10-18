import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'exit_confirmation_dialog.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  Future<void> _handlePop(BuildContext context) async {
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }

    final shouldExit = await showExitConfirmationDialog(context);
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop(context);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            height: 72,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_rounded),
                selectedIcon: Icon(
                  Icons.space_dashboard_rounded,
                  color: AppColors.primary,
                ),
                label: 'الرئيسية',
                tooltip: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_rounded),
                selectedIcon: Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                ),
                label: 'المشتركين',
                tooltip: 'المشتركين',
              ),
              NavigationDestination(
                icon: Icon(Icons.card_membership_rounded),
                selectedIcon: Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.primary,
                ),
                label: 'الباقات',
                tooltip: 'الباقات',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_rounded),
                selectedIcon: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
                label: 'الحسابات',
                tooltip: 'الحسابات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
