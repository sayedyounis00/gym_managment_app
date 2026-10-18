import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/dashboard/domain/entities/expiring_subscription.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/expiring_list.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/finance_summary.dart';
import 'package:gym_managment_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('Dashboard Widget Tests', () {
    testWidgets('ExpiringListSection displays empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpiringListSection(expiringSoon: []),
          ),
        ),
      );

      expect(find.text('تنتهي قريباً (خلال 7 أيام)'), findsOneWidget);
      expect(find.text('0 مشترك'), findsOneWidget);
      expect(find.text('جميع الاشتراكات سارية'), findsOneWidget);
      expect(find.text('لا توجد اشتراكات تنتهي خلال الـ 7 أيام القادمة.'), findsOneWidget);
    });

    testWidgets('ExpiringListSection displays member items with badges', (tester) async {
      final expiringItems = [
        ExpiringSubscription(
          memberId: 1,
          memberName: 'أحمد محمود',
          phone: '+201012345678',
          endDate: DateTime.now(),
          daysLeft: 0,
          packageName: 'باقة شهرية',
        ),
        ExpiringSubscription(
          memberId: 2,
          memberName: 'سارة علي',
          phone: '+201098765432',
          endDate: DateTime.now().add(const Duration(days: 3)),
          daysLeft: 3,
          packageName: 'باقة ربع سنوية',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpiringListSection(expiringSoon: expiringItems),
            ),
          ),
        ),
      );

      expect(find.text('2 مشترك'), findsOneWidget);
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('سارة علي'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('3 أيام'), findsOneWidget);
      expect(find.byIcon(Symbols.call_rounded), findsNWidgets(2));
      expect(find.byIcon(Symbols.chat_bubble_outline_rounded), findsNWidgets(2));
    });

    testWidgets('FinanceSummaryCard handles negative-profit state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceSummaryCard(
                revenue: 200.0,
                expenses: 800.0,
                todayRevenue: 0.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ملخص الحسابات'), findsOneWidget);
      expect(find.text('الإيرادات'), findsWidgets);
      expect(find.text('المصروفات'), findsWidgets);
      expect(find.text('صافي الأرباح (الشهر الحالي)'), findsOneWidget);
    });

    testWidgets('StatCard displays title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'المشتركين النشطين',
              value: '42',
              icon: Icons.people,
              accentColor: Colors.blue,
              subtitle: 'اشتراك سارٍ',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('المشتركين النشطين'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('اشتراك سارٍ'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });
}
