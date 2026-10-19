import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:drift/native.dart';

import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/features/members/presentation/pages/members_page.dart';
import 'package:gym_managment_app/features/memberships/presentation/pages/packages_page.dart';
import 'package:gym_managment_app/features/finance/presentation/pages/finance_page.dart';

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

  testWidgets('renders NavigationBar with 4 items and navigates to placeholders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pump();

    // Verify NavigationBar exists
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify all 4 tab destinations are present
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المشتركين'), findsOneWidget);
    expect(find.text('الباقات'), findsOneWidget);
    expect(find.text('الحسابات'), findsWidgets);

    // Initial page is Dashboard
    expect(find.text('لوحة التحكم'), findsOneWidget);

    // Navigate to Members
    await tester.tap(find.text('المشتركين'));
    await tester.pumpAndSettle();
    expect(find.byType(MembersPage), findsOneWidget);

    // Navigate to Memberships
    await tester.tap(find.text('الباقات'));
    await tester.pumpAndSettle();
    expect(find.byType(PackagesPage), findsOneWidget);

    // Navigate to Finance
    await tester.tap(find.text('الحسابات').last);
    await tester.pumpAndSettle();
    expect(find.byType(FinancePage), findsOneWidget);

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('clicking dashboard cards updates bottom nav bar selectedIndex',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial selectedIndex is 0 (Dashboard / الرئيسية)
    var navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // Tap active members card
    await tester.tap(find.text('المشتركين النشطين'));
    await tester.pumpAndSettle();

    // Verify navigated to Members section and nav bar updated to index 1 (المشتركين)
    expect(find.byType(MembersPage), findsOneWidget);
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1);

    // Navigate back to Dashboard tab
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);

    // Tap net profit card
    await tester.tap(find.text('صافي الأرباح'));
    await tester.pumpAndSettle();

    // Verify navigated to Finance section and nav bar updated to index 3 (الحسابات)
    expect(find.byType(FinancePage), findsOneWidget);
    navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 3);

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('navigating to Finance and then to Packages does not cause Hero tag collisions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pump();

    // Navigate to Finance first (tab index 3)
    await tester.tap(find.text('الحسابات').last);
    await tester.pumpAndSettle();
    expect(find.byType(FinancePage), findsOneWidget);

    // Navigate to Packages (tab index 2)
    await tester.tap(find.text('الباقات'));
    await tester.pumpAndSettle();
    expect(find.byType(PackagesPage), findsOneWidget);

    // Navigate to Members (tab index 1)
    await tester.tap(find.text('المشتركين'));
    await tester.pumpAndSettle();
    expect(find.byType(MembersPage), findsOneWidget);

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

