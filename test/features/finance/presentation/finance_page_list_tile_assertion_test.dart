import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_theme.dart';

void main() {
  testWidgets('ExpansionTile in Material surface does not throw ListTile background assertion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: true,
                title: const Text('مشتركون عليهم مستحقات'),
                children: const [
                  ListTile(
                    title: Text('مشترك 1'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Pump and verify no assertion was thrown
    await tester.pumpAndSettle();
    expect(find.text('مشتركون عليهم مستحقات'), findsOneWidget);
    expect(find.text('مشترك 1'), findsOneWidget);
  });
}
