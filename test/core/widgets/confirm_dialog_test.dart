import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/confirm_dialog.dart';

void main() {
  testWidgets('ConfirmDialog renders without overflow with long Arabic labels on standard screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ConfirmDialog.show(
                    context,
                    title: 'تجاهل التغييرات؟',
                    message: 'لديك بيانات غير محفوظة، هل أنت متأكد من رغبتك في الرجوع دون حفظ؟',
                    confirmLabel: 'تجاهل التغييرات',
                    cancelLabel: 'متابعة التعديل',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
    expect(find.text('متابعة التعديل'), findsOneWidget);
    expect(find.text('تجاهل التغييرات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ConfirmDialog wraps without overflow on very small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ConfirmDialog.show(
                    context,
                    title: 'تجاهل التغييرات؟',
                    message: 'لديك بيانات غير محفوظة، هل أنت متأكد من رغبتك في الرجوع دون حفظ؟',
                    confirmLabel: 'تجاهل التغييرات',
                    cancelLabel: 'متابعة التعديل',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
    expect(find.text('متابعة التعديل'), findsOneWidget);
    expect(find.text('تجاهل التغييرات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
