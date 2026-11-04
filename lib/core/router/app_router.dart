import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/members/presentation/cubit/member_details/member_details_cubit.dart';
import '../../features/members/presentation/cubit/member_form/member_form_cubit.dart';
import '../../features/members/presentation/cubit/member_notes/member_notes_cubit.dart';
import '../../features/members/presentation/cubit/attendance/attendance_cubit.dart';
import '../../features/members/presentation/cubit/members_list/members_list_cubit.dart';
import '../../features/members/presentation/pages/add_edit_member_page.dart';
import '../../features/members/presentation/pages/member_details_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/memberships/presentation/cubit/packages/packages_cubit.dart';
import '../../features/memberships/presentation/cubit/package_form/package_form_cubit.dart';
import '../../features/memberships/presentation/pages/packages_page.dart';
import '../../features/memberships/presentation/pages/add_edit_package_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/backup_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/finance/presentation/pages/add_expense_page.dart';
import '../../features/finance/presentation/pages/add_payment_page.dart';
import '../../features/finance/presentation/pages/reports_page.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../di/injection_container.dart';
import '../widgets/app_exit_scope.dart';
import '../widgets/main_shell_screen.dart';
import 'routes.dart';

class KeyboardDismissNavigatorObserver extends NavigatorObserver {
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismissKeyboard();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final GlobalKey<NavigatorState> _defaultRootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({
  GlobalKey<NavigatorState>? rootNavigatorKey,
  String initialLocation = AppRoutes.splash,
}) {
  final navKey = rootNavigatorKey ?? GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: navKey,
    initialLocation: initialLocation,
    observers: [
      KeyboardDismissNavigatorObserver(),
    ],
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<DashboardCubit>()..init(),
                child: const DashboardPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.members,
              builder: (context, state) {
                final status = state.uri.queryParameters['status'];
                return BlocProvider(
                  key: ValueKey('members_${status ?? "all"}'),
                  create: (_) => sl<MembersListCubit>(),
                  child: MembersPage(
                    key: ValueKey('members_page_${status ?? "all"}'),
                    initialStatusFilter: status,
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.memberships,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<PackagesCubit>()..init(),
                child: const PackagesPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.finance,
              builder: (context, state) => const FinancePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.addMember,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<MemberFormCubit>(),
          child: const AddEditMemberPage(),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.memberDetails,
      pageBuilder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return MaterialPage(
          key: state.pageKey,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<MemberDetailsCubit>()),
              BlocProvider(create: (_) => sl<MemberNotesCubit>()),
              BlocProvider(create: (_) => sl<AttendanceCubit>()),
            ],
            child: MemberDetailsPage(memberId: id),
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.editMember,
      pageBuilder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<MemberFormCubit>(),
            child: AddEditMemberPage(memberId: id),
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.addPackage,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: AppExitScope(
          child: BlocProvider(
            create: (_) => sl<PackageFormCubit>(),
            child: const AddEditPackagePage(),
          ),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.editPackage,
      pageBuilder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return MaterialPage(
          key: state.pageKey,
          child: AppExitScope(
            child: BlocProvider(
              create: (_) => sl<PackageFormCubit>(),
              child: AddEditPackagePage(packageId: id),
            ),
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.settings,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AppExitScope(
          child: SettingsPage(),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.backup,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AppExitScope(
          child: BackupPage(),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.addExpense,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AppExitScope(
          child: AddExpensePage(),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.addPayment,
      pageBuilder: (context, state) {
        final memberIdStr = state.uri.queryParameters['memberId'];
        final memberId = memberIdStr != null ? int.tryParse(memberIdStr) : null;
        return MaterialPage(
          key: state.pageKey,
          child: AppExitScope(
            child: AddPaymentPage(preselectedMemberId: memberId),
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.financeReports,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const AppExitScope(
          child: ReportsPage(),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<NotificationsCubit>()..init(),
          child: const AppExitScope(
            child: NotificationsPage(),
          ),
        ),
      ),
    ),
    GoRoute(
      parentNavigatorKey: navKey,
      path: AppRoutes.splash,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const SplashPage(),
      ),
    ),
  ],
);
}

GoRouter appRouter = createAppRouter(rootNavigatorKey: _defaultRootNavigatorKey);
