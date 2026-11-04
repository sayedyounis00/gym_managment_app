import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/app.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/core/router/app_router.dart';
import 'package:gym_managment_app/core/router/routes.dart';
import 'package:gym_managment_app/features/finance/presentation/pages/finance_page.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_cubit.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/floating_pin_dialog.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/pin_pad.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/secure_blur_wrapper.dart';

void main() {
  late AppDatabase testDb;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);
    appRouter.go(AppRoutes.dashboard);
  });

  tearDown(() async {
    await testDb.close();
    await sl.reset();
  });

  testWidgets(
      'dashboard cards are blurred except expiring soon, and unlocking via PIN reveals them',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify security cubit starts in locked state
    final securityCubit = sl<SecurityCubit>();
    expect(securityCubit.state.isLocked, true);

    // Verify blurred wrappers exist for sensitive cards
    final blurredWrappers = tester
        .widgetList<SecureBlurWrapper>(find.byType(SecureBlurWrapper))
        .toList();

    expect(blurredWrappers.length, 4); // 3 stat cards + 1 finance widget
    for (final wrapper in blurredWrappers) {
      expect(wrapper.isBlurred, true);
    }

    // "ينتهي قريباً" card must NOT be wrapped with isBlurred
    expect(find.text('ينتهي قريباً'), findsOneWidget);

    // Tap on a blurred lock badge
    await tester.tap(find.text('محمي • انقر للفتح').first);
    await tester.pumpAndSettle();

    // Floating PIN Dialog appears
    expect(find.byType(FloatingPinDialog), findsOneWidget);

    // Enter default PIN 0000
    final zeroButton =
        find.descendant(of: find.byType(PinPad), matching: find.text('0'));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pumpAndSettle();

    // Dialog is dismissed and cards are unblurred
    expect(find.byType(FloatingPinDialog), findsNothing);
    expect(securityCubit.state.isLocked, false);

    final unblurredWrappers = tester
        .widgetList<SecureBlurWrapper>(find.byType(SecureBlurWrapper))
        .toList();
    for (final wrapper in unblurredWrappers) {
      expect(wrapper.isBlurred, false);
    }

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'clicking finance tab in navigation bar requires PIN when locked, stays on current tab if dismissed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final securityCubit = sl<SecurityCubit>();
    expect(securityCubit.state.isLocked, true);

    // Tap Finance tab in navigation bar
    await tester.tap(find.text('الحسابات').last);
    await tester.pumpAndSettle();

    // Floating PIN dialog appears and Finance page is NOT shown yet
    expect(find.byType(FloatingPinDialog), findsOneWidget);
    expect(find.byType(FinancePage), findsNothing);

    // Dismiss dialog via close button
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();

    // Still on Dashboard, not in Finance
    expect(find.byType(FinancePage), findsNothing);
    expect(find.text('لوحة التحكم'), findsOneWidget);

    // Tap Finance again and enter correct PIN 0000
    await tester.tap(find.text('الحسابات').last);
    await tester.pumpAndSettle();

    final zeroButton =
        find.descendant(of: find.byType(PinPad), matching: find.text('0'));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pumpAndSettle();

    // Now Finance page is opened!
    expect(find.byType(FinancePage), findsOneWidget);

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
