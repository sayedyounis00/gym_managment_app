import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gym_managment_app/features/security/data/datasources/security_local_datasource.dart';
import 'package:gym_managment_app/features/security/data/repositories/security_repository_impl.dart';
import 'package:gym_managment_app/features/security/presentation/cubit/security_cubit.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/change_pin_dialog.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/floating_pin_dialog.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/pin_pad.dart';
import 'package:gym_managment_app/features/security/presentation/widgets/secure_blur_wrapper.dart';

void main() {
  final sl = GetIt.instance;
  late SecurityCubit cubit;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await sl.reset();
    const storage = FlutterSecureStorage();
    final localDataSource = SecurityLocalDataSourceImpl(secureStorage: storage);
    final repository = SecurityRepositoryImpl(localDataSource: localDataSource);
    cubit = SecurityCubit(repository: repository);
    await cubit.init();
    sl.registerSingleton<SecurityCubit>(cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestable(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: child,
        ),
      ),
    );
  }

  testWidgets('SecureBlurWrapper shows blur and lock badge when isBlurred is true',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestable(
        SecureBlurWrapper(
          isBlurred: true,
          onUnlockRequested: () => tapped = true,
          child: const Text('Sensitive Content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محمي • انقر للفتح'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.tap(find.text('محمي • انقر للفتح'));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('SecureBlurWrapper does not show overlay when isBlurred is false',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestable(
        SecureBlurWrapper(
          isBlurred: false,
          child: const Text('Sensitive Content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محمي • انقر للفتح'), findsNothing);
    expect(find.text('Sensitive Content'), findsOneWidget);
  });

  testWidgets('FloatingPinDialog enters PIN 0000 and unlocks successfully',
      (WidgetTester tester) async {
    bool? dialogResult;

    await tester.pumpWidget(
      buildTestable(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                dialogResult = await FloatingPinDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Dialog elements exist
    expect(find.text('حماية البيانات'), findsOneWidget);
    expect(find.text('الرمز الافتراضي: 0000'), findsOneWidget);
    expect(find.byType(PinPad), findsOneWidget);

    // Enter 0000 via keypad
    final zeroButton = find.text('0');
    expect(zeroButton, findsOneWidget);

    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zeroButton);
    await tester.pumpAndSettle();

    // Dialog dismissed with true
    expect(find.byType(FloatingPinDialog), findsNothing);
    expect(dialogResult, true);
    expect(cubit.state.isLocked, false);
  });

  testWidgets('FloatingPinDialog shows error when wrong PIN entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestable(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => FloatingPinDialog.show(context),
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap 1, 2, 3, 4
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    // Error message displayed
    expect(find.text('رمز المرور غير صحيح، يرجى المحاولة مرة أخرى'), findsOneWidget);
    expect(cubit.state.isLocked, true);
  });

  testWidgets('ChangePinDialog validates and changes PIN successfully',
      (WidgetTester tester) async {
    bool? changeResult;

    await tester.pumpWidget(
      buildTestable(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                changeResult = await ChangePinDialog.show(context);
              },
              child: const Text('Open Change Dialog'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Change Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('تغيير رمز المرور'), findsOneWidget);

    // Enter current PIN 0000, new PIN 1234, confirm PIN 1234
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3));

    await tester.enterText(textFields.at(0), '0000');
    await tester.enterText(textFields.at(1), '1234');
    await tester.enterText(textFields.at(2), '1234');
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ رمز المرور الجديد'));
    await tester.pumpAndSettle();

    expect(changeResult, true);
    expect(cubit.state.hasCustomPin, true);
  });
}
