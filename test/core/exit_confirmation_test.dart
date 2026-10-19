import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:drift/native.dart';
import 'package:gym_managment_app/features/members/presentation/pages/members_page.dart';

void main() {
  late AppDatabase testDb;

  setUp(() async {
    testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);
    appRouter.go(AppRoutes.dashboard);
  });

  tearDown(() async {
    await testDb.close();
    await sl.reset();
  });

  testWidgets('handles exit confirmation and back navigation appropriately',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // Verify initially on Dashboard (index 0)
    var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // 1. Popping from Dashboard shows the exit confirmation dialog
    unawaited(appRouter.routerDelegate.popRoute());
    await tester.pumpAndSettle();

    // Verify exit alert dialog content
    expect(find.text('الخروج من التطبيق'), findsOneWidget);
    expect(find.text('هل أنت متأكد من رغبتك في إغلاق التطبيق؟'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('خروج'), findsOneWidget);

    // 2. Dismissing via "إلغاء" stays in the app
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('الخروج من التطبيق'), findsNothing);
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // 3. Navigate to Members tab (index 1)
    await tester.tap(find.text('المشتركين'));
    await tester.pumpAndSettle();

    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1);
    expect(find.byType(MembersPage), findsOneWidget);

    // 4. Back press on non-home tab redirects back to Dashboard tab
    await appRouter.routerDelegate.popRoute();
    await tester.pumpAndSettle();

    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
    expect(find.text('الخروج من التطبيق'), findsNothing);

    // 5. Back press on Dashboard again triggers the exit dialog
    unawaited(appRouter.routerDelegate.popRoute());
    await tester.pumpAndSettle();
    expect(find.text('الخروج من التطبيق'), findsOneWidget);

    // 6. Confirming via "خروج" calls SystemNavigator.pop
    var popCalled = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SystemNavigator.pop') {
          popCalled = true;
        }
        return null;
      },
    );

    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(popCalled, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('navigating to member details from dashboard pops back to dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // Verify on Dashboard initially
    var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // Push Member Details route from Dashboard
    final BuildContext dashboardContext = tester.element(find.byType(NavigationBar));
    dashboardContext.push(AppRoutes.memberDetailsPath(1));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المشترك'), findsOneWidget);

    // Back press returns to Dashboard
    await appRouter.routerDelegate.popRoute();
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المشترك'), findsNothing);
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // Pressing back on Dashboard now triggers the exit dialog
    unawaited(appRouter.routerDelegate.popRoute());
    await tester.pumpAndSettle();
    expect(find.text('الخروج من التطبيق'), findsOneWidget);

    // Dismiss dialog to clean up pending timers
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('direct member details route with no history falls back to dashboard on back',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // Directly navigate to member details (no prior history)
    appRouter.go(AppRoutes.memberDetailsPath(1));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المشترك'), findsOneWidget);

    // Back press falls back to Dashboard rather than exiting directly
    await appRouter.routerDelegate.popRoute();
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المشترك'), findsNothing);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('standalone route about to exit triggers exit confirmation dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // Directly navigate to settings (no prior history)
    appRouter.go(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);

    // Back press triggers exit alert dialog
    unawaited(appRouter.routerDelegate.popRoute());
    await tester.pumpAndSettle();

    expect(find.text('الخروج من التطبيق'), findsOneWidget);
    expect(find.text('هل أنت متأكد من رغبتك في إغلاق التطبيق؟'), findsOneWidget);

    // Dismissing stays on settings
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('الخروج من التطبيق'), findsNothing);
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
