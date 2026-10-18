import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
