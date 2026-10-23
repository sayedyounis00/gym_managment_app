import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/bmi_result.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';
import 'package:gym_managment_app/features/members/domain/entities/member.dart';
import 'package:gym_managment_app/features/members/domain/usecases/delete_member.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_member_details.dart';
import 'package:gym_managment_app/features/members/domain/usecases/record_payment.dart';
import 'package:gym_managment_app/features/members/domain/usecases/toggle_member_suspension.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/member_details/member_details_cubit.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/member_details/member_details_state.dart';
import 'package:gym_managment_app/features/memberships/domain/usecases/delete_subscription.dart';
import 'package:gym_managment_app/features/memberships/domain/usecases/end_subscription.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMemberDetails extends Mock implements GetMemberDetails {}
class MockToggleMemberSuspension extends Mock implements ToggleMemberSuspension {}
class MockDeleteMember extends Mock implements DeleteMember {}
class MockRecordPayment extends Mock implements RecordPayment {}
class MockDeleteSubscription extends Mock implements DeleteSubscription {}
class MockEndSubscription extends Mock implements EndSubscription {}

void main() {
  late MockGetMemberDetails mockGetMemberDetails;
  late MockToggleMemberSuspension mockToggleMemberSuspension;
  late MockDeleteMember mockDeleteMember;
  late MockRecordPayment mockRecordPayment;
  late MockDeleteSubscription mockDeleteSubscription;
  late MockEndSubscription mockEndSubscription;
  late MemberDetailsCubit cubit;

  final now = DateTime.now();

  final initialMember = Member(
    id: 1,
    name: 'حسام حسن',
    phone: '01012345678',
    gender: Gender.male,
    weightKg: 95.0,
    heightCm: 180.0,
    createdAt: now,
    updatedAt: now,
  );

  final updatedMember = initialMember.copyWith(
    weightKg: 75.0,
  );

  final initialDetailsData = MemberDetailsData(
    member: initialMember,
    status: MemberStatusType.active,
    subscriptions: const [],
    payments: const [],
    hasPayments: false,
  );

  final updatedDetailsData = MemberDetailsData(
    member: updatedMember,
    status: MemberStatusType.active,
    subscriptions: const [],
    payments: const [],
    hasPayments: false,
  );

  setUp(() {
    mockGetMemberDetails = MockGetMemberDetails();
    mockToggleMemberSuspension = MockToggleMemberSuspension();
    mockDeleteMember = MockDeleteMember();
    mockRecordPayment = MockRecordPayment();
    mockDeleteSubscription = MockDeleteSubscription();
    mockEndSubscription = MockEndSubscription();

    cubit = MemberDetailsCubit(
      getMemberDetails: mockGetMemberDetails,
      toggleMemberSuspension: mockToggleMemberSuspension,
      deleteMember: mockDeleteMember,
      recordPaymentUseCase: mockRecordPayment,
      deleteSubscriptionUseCase: mockDeleteSubscription,
      endSubscriptionUseCase: mockEndSubscription,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('MemberDetailsCubit BMI and weight update tests', () {
    test('initial member computes overweight BMI', () {
      expect(initialMember.bmi, isNotNull);
      // 95 / (1.8 * 1.8) = 95 / 3.24 = 29.32... -> 29.3
      expect(initialMember.bmi!.value, equals(29.3));
      expect(initialMember.bmi!.category, equals(BmiCategory.overweight));
    });

    test('updated member with reduced weight computes normal BMI', () {
      expect(updatedMember.bmi, isNotNull);
      // 75 / (1.8 * 1.8) = 75 / 3.24 = 23.148... -> 23.1
      expect(updatedMember.bmi!.value, equals(23.1));
      expect(updatedMember.bmi!.category, equals(BmiCategory.normal));
    });

    blocTest<MemberDetailsCubit, MemberDetailsState>(
      'updating weight and refreshing emits member with new BMI',
      build: () {
        var callCount = 0;
        when(() => mockGetMemberDetails(1)).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return Right(initialDetailsData);
          } else {
            return Right(updatedDetailsData);
          }
        });
        return cubit;
      },
      act: (cubit) async {
        await cubit.load(1);
        await cubit.refresh();
      },
      expect: () => [
        const MemberDetailsLoading(),
        MemberDetailsLoaded(data: initialDetailsData),
        MemberDetailsLoaded(data: updatedDetailsData),
      ],
      verify: (_) {
        final state = cubit.state;
        expect(state, isA<MemberDetailsLoaded>());
        final currentMember = (state as MemberDetailsLoaded).data.member;
        expect(currentMember.weightKg, equals(75.0));
        expect(currentMember.bmi!.value, equals(23.1));
        expect(currentMember.bmi!.category, equals(BmiCategory.normal));
      },
    );

    test('endSubscription calls endSubscriptionUseCase and returns true on success', () async {
      when(() => mockEndSubscription(10)).thenAnswer((_) async => const Right(unit));
      when(() => mockGetMemberDetails(1)).thenAnswer((_) async => Right(initialDetailsData));

      await cubit.load(1);
      final result = await cubit.endSubscription(10);
      expect(result, isTrue);
      verify(() => mockEndSubscription(10)).called(1);
    });
  });
}
