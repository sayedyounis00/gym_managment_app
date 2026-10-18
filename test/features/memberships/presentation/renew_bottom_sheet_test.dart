import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_managment_app/core/widgets/app_button.dart';
import 'package:gym_managment_app/core/widgets/date_field.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/memberships/domain/entities/membership_package.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/renew/renew_cubit.dart';
import 'package:gym_managment_app/features/memberships/presentation/cubit/renew/renew_state.dart';
import 'package:gym_managment_app/features/memberships/presentation/widgets/renew_bottom_sheet.dart';

class MockRenewCubit extends MockCubit<RenewState> implements RenewCubit {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });
  final samplePackage = MembershipPackage(
    id: 1,
    name: 'باقة شهرية ذهبية',
    durationValue: 1,
    durationUnit: 'months',
    price: 350.0,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  group('DateField Responsive Tests', () {
    testWidgets('renders properly in tight width without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 140, // very tight width simulating 2-column on 320dp screen
                  child: DateField(
                    label: 'تاريخ الانتهاء',
                    value: DateTime(2026, 11, 19),
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DateField), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);
    });
  });

  group('RenewBottomSheet UI & Responsiveness Tests', () {
    late MockRenewCubit mockRenewCubit;

    setUp(() {
      mockRenewCubit = MockRenewCubit();
    });

    Widget buildSheet({required RenewState state}) {
      whenListen(
        mockRenewCubit,
        Stream.fromIterable([state]),
        initialState: state,
      );

      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BlocProvider<RenewCubit>.value(
              value: mockRenewCubit,
              child: const RenewBottomSheet(
                memberId: 10,
                memberName: 'أحمد محمود',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders fully paid status cleanly without duplicate badges', (tester) async {
      final state = RenewState(
        isLoading: false,
        memberId: 10,
        memberName: 'أحمد محمود',
        startDate: DateTime(2026, 10, 19),
        endDate: DateTime(2026, 11, 19),
        selectedPackage: samplePackage,
        amountPaid: 350.0,
      );

      await tester.pumpWidget(buildSheet(state: state));
      await tester.pump();

      // Check single status chip
      expect(find.byType(StatusChip), findsOneWidget);
      expect(find.text('حالة السداد:'), findsOneWidget);
      expect(find.text('تم الدفع بالكامل'), findsOneWidget);

      // Verify button has isFullWidth = true
      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);
      final appButton = tester.widget<AppButton>(buttonFinder);
      expect(appButton.isFullWidth, isTrue);
    });

    testWidgets('renders remaining debt cleanly when remainingAmount > 0', (tester) async {
      final state = RenewState(
        isLoading: false,
        memberId: 10,
        memberName: 'أحمد محمود',
        startDate: DateTime(2026, 10, 19),
        endDate: DateTime(2026, 11, 19),
        selectedPackage: samplePackage,
        amountPaid: 200.0,
      );

      await tester.pumpWidget(buildSheet(state: state));
      await tester.pump();

      expect(find.text('المبلغ المتبقي دين:'), findsOneWidget);
      expect(find.byType(StatusChip), findsNothing);
    });

    testWidgets('displays only cash and wallet payment methods, without transfer', (tester) async {
      final state = RenewState(
        isLoading: false,
        memberId: 10,
        memberName: 'أحمد محمود',
        startDate: DateTime(2026, 10, 19),
        endDate: DateTime(2026, 11, 19),
        selectedPackage: samplePackage,
        amountPaid: 350.0,
      );

      await tester.pumpWidget(buildSheet(state: state));
      await tester.pump();

      expect(find.text('نقدي'), findsOneWidget);
      expect(find.text('محفظة إلكترونية'), findsOneWidget);
    });
  });
}
