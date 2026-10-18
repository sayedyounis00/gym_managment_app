import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/expiring_subscription.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/expiring_list.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/finance_summary.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('Responsive Dashboard Widget Tests', () {
    testWidgets('StatCard renders without overflow on narrow width (140px)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 110,
                child: StatCard(
                  title: 'المشتركين النشطين',
                  value: '1,429',
                  icon: Icons.people,
                  accentColor: Colors.blue,
                  subtitle: 'اشتراك سارٍ',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('المشتركين النشطين'), findsOneWidget);
      expect(find.text('1,429'), findsOneWidget);
    });

    testWidgets('StatCard handles high text scale (1.5x) without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 160,
                  height: 120,
                  child: StatCard(
                    title: 'إيراد اليوم',
                    value: '99,999 ج.م',
                    icon: Icons.monetization_on,
                    accentColor: Colors.green,
                    subtitle: 'إيرادات اليوم',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('إيراد اليوم'), findsOneWidget);
    });

    testWidgets('FinanceSummaryCard renders without overflow on 320px phone width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceSummaryCard(
                revenue: 12500.50,
                expenses: 4200.00,
                todayRevenue: 650.00,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ملخص الحسابات'), findsOneWidget);
      expect(find.text('الإيرادات'), findsWidgets);
      expect(find.text('المصروفات'), findsWidgets);
      expect(find.text('صافي الأرباح (الشهر الحالي)'), findsOneWidget);
    });

    testWidgets('ExpiringListSection renders smoothly on 320px phone width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        ExpiringSubscription(
          memberId: 1,
          memberName: 'ألكسندر هاميلتون اسم طويل جداً',
          phone: '+201012345678',
          endDate: DateTime.now(),
          daysLeft: 0,
          packageName: 'اشتراك سنوي في آي بي',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpiringListSection(expiringSoon: items),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ألكسندر هاميلتون اسم طويل جداً'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.byIcon(Symbols.call_rounded), findsOneWidget);
      expect(find.byIcon(Symbols.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('ExpiringListSection renders on tablet/desktop wide viewport (1200px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        ExpiringSubscription(
          memberId: 1,
          memberName: 'سارة علي',
          phone: '+201098765432',
          endDate: DateTime.now().add(const Duration(days: 2)),
          daysLeft: 2,
          packageName: 'باقة شهرية',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpiringListSection(expiringSoon: items),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('2 أيام'), findsOneWidget);
    });
  });
}
