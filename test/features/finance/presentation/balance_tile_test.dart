import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gym_managment_app/features/finance/domain/entities/member_balance.dart';
import 'package:gym_managment_app/features/finance/presentation/widgets/balance_tile.dart';

void main() {
  group('BalanceTile WhatsApp logic tests', () {
    test('buildWhatsAppMessage correctly formats template with month and integer amount', () {
      final msg = BalanceTile.buildWhatsAppMessage(
        monthName: 'أكتوبر',
        amount: 250.0,
      );

      const expected = 'السلام عليكم ورحمة الله وبركاته،\n\n'
          'الكابتن أحمد بيفكّر حضرتك بالمستحقات المتبقية عن شهر أكتوبر.\n\n'
          'إجمالي المبلغ المستحق: 250 جنيه.\n\n'
          'شكرًا لحضرتك، ونتمنى لك يومًا سعيدًا.';

      expect(msg, equals(expected));
    });

    test('buildWhatsAppMessage correctly formats template with decimal amount', () {
      final msg = BalanceTile.buildWhatsAppMessage(
        monthName: 'مارس',
        amount: 175.50,
      );

      const expected = 'السلام عليكم ورحمة الله وبركاته،\n\n'
          'الكابتن أحمد بيفكّر حضرتك بالمستحقات المتبقية عن شهر مارس.\n\n'
          'إجمالي المبلغ المستحق: 175.50 جنيه.\n\n'
          'شكرًا لحضرتك، ونتمنى لك يومًا سعيدًا.';

      expect(msg, equals(expected));
    });

    test('formatPhoneForWhatsApp normalizes Egyptian local numbers to international format', () {
      expect(BalanceTile.formatPhoneForWhatsApp('01012345678'), equals('201012345678'));
      expect(BalanceTile.formatPhoneForWhatsApp('01123456789'), equals('201123456789'));
      expect(BalanceTile.formatPhoneForWhatsApp('01234567890'), equals('201234567890'));
      expect(BalanceTile.formatPhoneForWhatsApp('01512345678'), equals('201512345678'));
    });

    test('formatPhoneForWhatsApp handles numbers with country code or Arabic digits', () {
      expect(BalanceTile.formatPhoneForWhatsApp('201012345678'), equals('201012345678'));
      expect(BalanceTile.formatPhoneForWhatsApp('+201012345678'), equals('201012345678'));
      expect(BalanceTile.formatPhoneForWhatsApp('٠١٠١٢٣٤٥٦٧٨'), equals('201012345678'));
    });

    test('getMonthName returns correct Arabic month name', () {
      expect(BalanceTile.getMonthName(DateTime(2026, 1, 1)), equals('يناير'));
      expect(BalanceTile.getMonthName(DateTime(2026, 5, 1)), equals('مايو'));
      expect(BalanceTile.getMonthName(DateTime(2026, 10, 1)), equals('أكتوبر'));
      expect(BalanceTile.getMonthName(DateTime(2026, 12, 1)), equals('ديسمبر'));
    });
  });

  group('BalanceTile Widget UI tests', () {
    const testBalance = MemberBalance(
      memberId: 1,
      memberName: 'أحمد محمود',
      memberPhone: '01012345678',
      totalDue: 500,
      totalPaid: 200,
      remaining: 300,
      activePackageName: 'اشتراك شهري',
    );

    testWidgets('renders official WhatsApp icon and does not render phone icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceTile(
              balance: testBalance,
              selectedMonth: DateTime(2026, 10, 1),
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify phone icon is NOT present
      expect(find.byIcon(Icons.phone_rounded), findsNothing);

      // Verify WhatsApp icon is present
      final faIconFinder = find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == FontAwesomeIcons.whatsapp.data,
      );
      expect(faIconFinder, findsOneWidget);

      // Verify tooltip
      final iconButtonFinder = find.ancestor(
        of: faIconFinder,
        matching: find.byType(IconButton),
      );
      expect(iconButtonFinder, findsOneWidget);
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.tooltip, equals('مراسلة واتساب'));

      // Verify member details and remaining amount are displayed
      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('اشتراك شهري'), findsOneWidget);
      expect(find.text('مستحق'), findsOneWidget);
    });
  });
}
