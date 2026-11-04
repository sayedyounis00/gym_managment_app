import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> _seedGoldenData(AppDatabase db) async {
  final now = DateTime.now();

  final pkgId = await db.into(db.packages).insert(
        PackagesCompanion.insert(
          name: 'باقة تدريب سنوية',
          durationInDays: 365,
          price: 1200.0,
        ),
      );

  final memberId = await db.into(db.members).insert(
        MembersCompanion.insert(
          name: 'كابتن محمود حسن',
          phone: '01122334455',
          status: const Value('active'),
          age: const Value(30),
        ),
      );

  await db.into(db.subscriptions).insert(
        SubscriptionsCompanion.insert(
          memberId: memberId,
          packageId: Value(pkgId),
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.add(const Duration(days: 355)),
          isRenewal: const Value(false),
          status: const Value('active'),
        ),
      );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    await initializeDateFormatting('ar', null);
    Intl.defaultLocale = 'ar';
  });

  group('Widget Golden Snapshots', () {
    late AppDatabase testDb;

    setUp(() async {
      await sl.reset();
      testDb = AppDatabase(NativeDatabase.memory());
      await initDependencies(database: testDb);
      await _seedGoldenData(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('Dashboard Screen Golden', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = createAppRouter(initialLocation: AppRoutes.dashboard);
      await tester.pumpWidget(GymApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GymApp),
        matchesGoldenFile('goldens/dashboard_screen.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Members Screen Golden', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = createAppRouter(initialLocation: AppRoutes.members);
      await tester.pumpWidget(GymApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GymApp),
        matchesGoldenFile('goldens/members_screen.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Finance Screen Golden', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = createAppRouter(initialLocation: AppRoutes.finance);
      await tester.pumpWidget(GymApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GymApp),
        matchesGoldenFile('goldens/finance_screen.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('Packages Screen Golden', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = createAppRouter(initialLocation: AppRoutes.memberships);
      await tester.pumpWidget(GymApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GymApp),
        matchesGoldenFile('goldens/packages_screen.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
