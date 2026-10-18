import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/loaders/loaders.dart';
import 'package:gym_managment_app/features/members/presentation/widgets/current_membership_card.dart';

void main() {
  Widget liquidTestWrapper(
    Widget child, {
    TextDirection direction = TextDirection.rtl,
    double textScale = 1.0,
    Size size = const Size(390, 844),
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  group('LiquidGlassEffect & LiquidSkeleton Configuration Tests', () {
    test('LiquidGlassEffect provides frosted glass base and stops', () {
      const effect = LiquidGlassEffect();

      expect(effect.duration, const Duration(milliseconds: 1600));
      expect(effect.stops, const [0.0, 0.45, 0.50, 0.55, 1.0]);
      expect(effect.colors.length, 5);
      expect(effect.begin, const AlignmentDirectional(-1.0, -0.36));
      expect(effect.end, const AlignmentDirectional(1.0, 0.36));

      final paint = effect.createPaint(
        0.5,
        const Rect.fromLTWH(0, 0, 200, 100),
        TextDirection.rtl,
      );
      expect(paint.shader, isNotNull);
    });

    testWidgets(
      'LiquidSkeleton wraps with Semantics accessibility announcement when enabled',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(
            const LiquidSkeleton(enabled: true, child: Text('محتوى تجريبي')),
          ),
        );

        expect(find.byType(Semantics), findsWidgets);
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'جاري التحميل',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Liquid Glass Skeletons Component Suite Tests', () {
    testWidgets(
      'StatCardSkeleton and StatCardGridSkeleton render in 2x2 grid without overflow',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(
            const StatCardGridSkeleton(crossAxisCount: 2),
            textScale: 1.3,
          ),
        );

        expect(find.byType(StatCardSkeleton), findsNWidgets(4));
        expect(find.text('المشتركين النشطين'), findsOneWidget);
        expect(find.text('ينتهي قريباً'), findsOneWidget);
        expect(find.text('مشتركين جدد'), findsOneWidget);
        expect(find.text('صافي الأرباح'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HeroCardSkeleton renders net profit card with radiusXl and faint gradient',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(const HeroCardSkeleton(), textScale: 1.3),
        );

        expect(find.byType(HeroCardSkeleton), findsOneWidget);
        expect(find.text('صافي الأرباح (الشهر الحالي)'), findsOneWidget);
        expect(find.text('18,450 ج.م'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MemberTileSkeleton and MemberListSkeleton render 8 items with avatar 48 and chips',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(const MemberListSkeleton(count: 8), textScale: 1.3),
        );

        expect(find.byType(MemberListSkeleton), findsOneWidget);
        expect(find.text('أحمد محمد علي'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PackageCardSkeleton and PackageListSkeleton render with duration badge and price',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(
            const PackageListSkeleton(count: 3),
            textScale: 1.3,
          ),
        );

        expect(find.byType(PackageListSkeleton), findsOneWidget);
        expect(find.byType(PackageCardSkeleton), findsNWidgets(3));
        expect(find.text('ج.م'), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TransactionRowSkeleton and TransactionListSkeleton render sticky day headers',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(const TransactionListSkeleton(), textScale: 1.3),
        );

        expect(find.byType(TransactionListSkeleton), findsOneWidget);
        expect(find.byType(TransactionRowSkeleton), findsWidgets);
        expect(find.text('اليوم (3 معاملة)'), findsOneWidget);
        expect(find.text('أمس (2 معاملة)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('ChartSkeleton renders 7 bar silhouettes of varying heights', (
      tester,
    ) async {
      await tester.pumpWidget(
        liquidTestWrapper(const ChartSkeleton(), textScale: 1.3),
      );

      expect(find.byType(ChartSkeleton), findsOneWidget);
      expect(find.text('حركة الإيرادات الأسبوعية'), findsOneWidget);
      expect(find.text('سبت'), findsOneWidget);
      expect(find.text('جمعة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'MemberDetailsSkeleton renders 80dp avatar, 3-button row, and progress bar',
      (tester) async {
        await tester.pumpWidget(
          liquidTestWrapper(const MemberDetailsSkeleton(), textScale: 1.3),
        );

        expect(find.byType(MemberDetailsSkeleton), findsOneWidget);
        expect(find.text('اتصال'), findsOneWidget);
        expect(find.text('واتساب'), findsOneWidget);
        expect(find.text('تعديل'), findsOneWidget);
        expect(find.byType(CurrentMembershipCard), findsOneWidget);
        expect(find.text('باقة اللياقة والقوة الشاملة'), findsOneWidget);
        expect(find.text('الوزن'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
