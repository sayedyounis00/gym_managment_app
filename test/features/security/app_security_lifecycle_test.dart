import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import 'package:gym_managment_app/core/di/injection_container.dart';
import 'package:gym_managment_app/features/finance/presentation/pages/finance_page.dart';
import 'package:gym_managment_app/features/security/data/services/security_native_service.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_cubit.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/app_security_barrier.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/floating_pin_dialog.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/pin_pad.dart';

void main() {
  late AppDatabase testDb;
  late SecurityCubit cubit;
  final List<MethodCall> methodCalls = [];

  setUp(() async {
    await initializeDateFormatting('ar', null);
    FlutterSecureStorage.setMockInitialValues({});
    methodCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.gym_managment_app/security'),
      (MethodCall call) async {
        methodCalls.add(call);
        return true;
      },
    );

    SecurityNativeService.enableInTests = true;
    testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: testDb);
    cubit = sl<SecurityCubit>();
    await cubit.init();
  });

  tearDown(() async {
    SecurityNativeService.enableInTests = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.gym_managment_app/security'),
      null,
    );
    await testDb.close();
    await sl.reset();
  });

  Widget buildTestable(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: BlocProvider.value(
        value: cubit,
        child: AppSecurityBarrier(child: child),
      ),
    );
  }

  testWidgets(
      'when app goes inactive or paused, security lock closes and privacy shield shows',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestable(
        const Scaffold(
          body: Center(child: Text('Dashboard Content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Unlock the app first
    cubit.unlock();
    await tester.pumpAndSettle();
    expect(cubit.state.isLocked, false);
    expect(find.text('نظام إدارة الجيم محمي'), findsNothing);

    // Simulate user leaving the app (AppLifecycleState.inactive / paused)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    // Lock must close immediately
    expect(cubit.state.isLocked, true);
    // Privacy shield must be displayed to block recent apps preview
    expect(find.text('نظام إدارة الجيم محمي'), findsOneWidget);

    // Simulate background paused
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(cubit.state.isLocked, true);
    expect(find.text('نظام إدارة الجيم محمي'), findsOneWidget);

    // Simulate user returning to the app (resumed)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Privacy shield lifted, but lock remains closed!
    expect(find.text('نظام إدارة الجيم محمي'), findsNothing);
    expect(cubit.state.isLocked, true);
  });

  testWidgets(
      'FinancePage shows locked screen when security is locked, and unlocks with PIN',
      (WidgetTester tester) async {
    // Start locked
    expect(cubit.state.isLocked, true);

    await tester.pumpWidget(
      buildTestable(
        const FinancePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Shows locked finance placeholder
    expect(find.text('صفحة الحسابات مقفلة'), findsOneWidget);
    expect(find.text('إدخال رمز المرور'), findsOneWidget);

    // Tap to enter PIN
    await tester.tap(find.text('إدخال رمز المرور'));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingPinDialog), findsOneWidget);

    // Enter 0000
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

    // Unlocked! Locked placeholder is gone and normal finance screen is visible
    expect(find.text('صفحة الحسابات مقفلة'), findsNothing);
    expect(cubit.state.isLocked, false);

    // Cleanly unmount widget tree before tearDown
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('SecurityNativeService sends setSecureMode to platform channel', () async {
    await SecurityNativeService.setSecureMode(true);
    expect(methodCalls.last.method, 'setSecureMode');
    expect(methodCalls.last.arguments, {'enabled': true});

    await SecurityNativeService.setSecureMode(false);
    expect(methodCalls.last.method, 'setSecureMode');
    expect(methodCalls.last.arguments, {'enabled': false});
  });
}
