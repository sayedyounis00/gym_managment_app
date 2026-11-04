import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> _seedDemoData(AppDatabase db) async {
  final now = DateTime.now();

  final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'اشتراك شهري مميز',
          durationInDays: 30,
          price: 150.0,
        ),
      );

  await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'اشتراك ربع سنوي',
          durationInDays: 90,
          price: 400.0,
        ),
      );

  final m1 = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'أحمد محمود',
          phone: '01012345678',
          status: const Value('active'),
          age: const Value(28),
        ),
      );

  final sub1 = await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: m1,
          packageId: Value(pkgId),
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 25)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );

  await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          memberId: m1,
          subscriptionId: Value(sub1),
          amount: 150.0,
          paidAt: Value(now.subtract(const Duration(days: 5))),
          paymentMethod: const Value('cash'),
        ),
      );

  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          title: 'فاتورة الكهرباء',
          amount: 450.0,
          category: const Value('utilities'),
          date: Value(now.subtract(const Duration(days: 2))),
        ),
      );

  await db.into(db.memberNotes).insert(
        MemberNotesCompanion.insert(
          memberId: m1,
          note: 'يفضل التدريب في الفترة الصباحية',
          createdAt: Value(now.subtract(const Duration(days: 1))),
        ),
      );

  await db.into(db.attendanceLogs).insert(
        AttendanceLogsCompanion.insert(
          memberId: m1,
          subscriptionId: sub1,
          attendedOn: now.subtract(const Duration(hours: 2)),
        ),
      );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await initializeDateFormatting('ar', null);
    Intl.defaultLocale = 'ar';
  });

  testWidgets('Capture screenshots for all app screens', (WidgetTester tester) async {
    await sl.reset();
    final testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);
    await _seedDemoData(testDb);

    late GoRouter router;

    Future<void> renderAndCapture(String routePath, String screenshotName) async {
      router = createAppRouter(initialLocation: routePath);
      await tester.pumpWidget(GymApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await binding.takeScreenshot(screenshotName);
    }

    // 1. Splash Screen
    await renderAndCapture(AppRoutes.splash, '01_splash');

    // 2. Dashboard Screen
    await renderAndCapture(AppRoutes.dashboard, '02_dashboard');

    // 3. Members List Screen
    await renderAndCapture(AppRoutes.members, '03_members_list');

    // 4. Member Details Screen
    await renderAndCapture(AppRoutes.memberDetailsPath(1), '04_member_details');

    // 5. Add Member Screen
    await renderAndCapture(AppRoutes.addMember, '05_add_member');

    // 6. Edit Member Screen
    await renderAndCapture(AppRoutes.editMemberPath(1), '06_edit_member');

    // 7. Packages / Memberships Screen
    await renderAndCapture(AppRoutes.memberships, '07_packages_list');

    // 8. Add Package Screen
    await renderAndCapture(AppRoutes.addPackage, '08_add_package');

    // 9. Edit Package Screen
    await renderAndCapture(AppRoutes.editPackagePath(1), '09_edit_package');

    // 10. Finance Overview Screen
    await renderAndCapture(AppRoutes.finance, '10_finance_overview');

    // 11. Add Expense Screen
    await renderAndCapture(AppRoutes.addExpense, '11_add_expense');

    // 12. Add Payment Screen
    await renderAndCapture(AppRoutes.addPayment, '12_add_payment');

    // 13. Finance Reports Screen
    await renderAndCapture(AppRoutes.financeReports, '13_finance_reports');

    // 14. Settings Screen
    await renderAndCapture(AppRoutes.settings, '14_settings');

    // 15. Backup Screen
    await renderAndCapture(AppRoutes.backup, '15_backup');

    // 16. Notifications Screen
    await renderAndCapture(AppRoutes.notifications, '16_notifications');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await testDb.close();
  });
}
