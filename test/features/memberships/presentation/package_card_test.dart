import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/package_card.dart';

void main() {
  final activePackage = MembershipPackage(
    id: 1,
    name: 'باقة شهرية ذهبية',
    durationValue: 1,
    durationUnit: 'months',
    price: 350.0,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final inactivePackage = MembershipPackage(
    id: 2,
    name: 'باقة يومية معطلة',
    durationValue: 1,
    durationUnit: 'days',
    price: 50.0,
    isActive: false,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget buildTestWidget({
    required MembershipPackage package,
    required VoidCallback onEdit,
    VoidCallback? onDelete,
    ValueChanged<bool>? onToggleActive,
    double textScale = 1.0,
    double width = 360,
  }) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: PackageCard(
                  package: package,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onToggleActive: onToggleActive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('PackageCard Widget Tests', () {
    testWidgets('renders active package details correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          package: activePackage,
          onEdit: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('باقة شهرية ذهبية'), findsOneWidget);
      expect(find.text('شهر واحد'), findsOneWidget);
      expect(find.text('مدة'), findsOneWidget);
      expect(find.textContaining('350'), findsOneWidget);
      expect(find.text('غير مفعلة'), findsNothing);
    });

    testWidgets('renders inactive package with badge', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          package: inactivePackage,
          onEdit: () {},
          onToggleActive: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('باقة يومية معطلة'), findsOneWidget);
      expect(find.text('يوم واحد'), findsOneWidget);
      expect(find.text('غير مفعلة'), findsOneWidget);
      expect(find.text('معطلة'), findsOneWidget);
    });

    testWidgets('triggers onEdit callback on card tap and button tap', (tester) async {
      int editCalls = 0;
      await tester.pumpWidget(
        buildTestWidget(
          package: activePackage,
          onEdit: () => editCalls++,
        ),
      );

      await tester.tap(find.byType(PackageCard));
      await tester.pump();
      expect(editCalls, 1);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(editCalls, 2);
    });

    testWidgets('triggers onToggleActive when switch changed', (tester) async {
      bool? toggledValue;
      await tester.pumpWidget(
        buildTestWidget(
          package: activePackage,
          onEdit: () {},
          onToggleActive: (val) => toggledValue = val,
        ),
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pump();
      expect(toggledValue, false);
    });

    testWidgets('renders without overflow on narrow width (300px) and text scale 1.3x with delete button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          package: activePackage,
          onEdit: () {},
          onDelete: () {},
          onToggleActive: (_) {},
          textScale: 1.3,
          width: 300,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('باقة شهرية ذهبية'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('triggers onDelete callback when delete button is tapped', (tester) async {
      int deleteCalls = 0;
      await tester.pumpWidget(
        buildTestWidget(
          package: activePackage,
          onEdit: () {},
          onDelete: () => deleteCalls++,
        ),
      );

      final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pump();
      expect(deleteCalls, 1);
    });

    testWidgets('renders pay-as-you-go package badge, open duration, and daily price correctly', (tester) async {
      final payAsYouGoPackage = MembershipPackage(
        id: 3,
        name: 'باقة يومية حسب الاستخدام',
        durationValue: 1,
        durationUnit: 'days',
        price: 30.0,
        isPayAsYouGo: true,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        buildTestWidget(
          package: payAsYouGoPackage,
          onEdit: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('باقة يومية حسب الاستخدام'), findsOneWidget);
      expect(find.text('نظام'), findsOneWidget);
      expect(find.text('حسب الاستخدام (مفتوح)'), findsOneWidget);
      expect(find.textContaining('30'), findsOneWidget);
      expect(find.textContaining('/ يوم'), findsOneWidget);
    });
  });
}
