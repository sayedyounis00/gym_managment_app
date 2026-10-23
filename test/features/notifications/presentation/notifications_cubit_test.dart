import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/domain/repositories/members_repository.dart';
import 'package:gym_managment_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:gym_managment_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:mocktail/mocktail.dart';

class MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late MockMembersRepository mockMembersRepository;

  setUp(() {
    mockMembersRepository = MockMembersRepository();
  });

  final expiringMember = MemberSummary(
    id: 1,
    name: 'أحمد محمود',
    phone: '01012345678',
    gender: Gender.male,
    status: MemberStatusType.expiringSoon,
    daysLeft: 2,
    packageName: 'باقة شهرية',
    subscriptionEndDate: DateTime.now().add(const Duration(days: 2)),
  );

  final expiredMemberRecent = MemberSummary(
    id: 2,
    name: 'سارة علي',
    phone: '01098765432',
    gender: Gender.female,
    status: MemberStatusType.expired,
    daysLeft: -5,
    packageName: 'باقة سنوية',
    subscriptionEndDate: DateTime.now().subtract(const Duration(days: 5)),
  );

  final expiredMemberTooOld = MemberSummary(
    id: 3,
    name: 'خالد سعيد',
    phone: '01122334455',
    gender: Gender.male,
    status: MemberStatusType.expired,
    daysLeft: -45,
    packageName: 'باقة شهرية',
    subscriptionEndDate: DateTime.now().subtract(const Duration(days: 45)),
  );

  final activeMember = MemberSummary(
    id: 4,
    name: 'منى إبراهيم',
    phone: '01234567890',
    gender: Gender.female,
    status: MemberStatusType.active,
    daysLeft: 20,
    packageName: 'باقة شهرية',
    subscriptionEndDate: DateTime.now().add(const Duration(days: 20)),
  );

  group('NotificationsCubit', () {
    test('initial state is NotificationsInitial', () {
      final cubit =
          NotificationsCubit(membersRepository: mockMembersRepository);
      expect(cubit.state, const NotificationsInitial());
      cubit.close();
    });

    blocTest<NotificationsCubit, NotificationsState>(
      'emits [NotificationsLoading, NotificationsLoaded] with separated expiring and recent expired members',
      build: () {
        when(() => mockMembersRepository.watchMembers()).thenAnswer(
          (_) => Stream.value([
            expiringMember,
            expiredMemberRecent,
            expiredMemberTooOld,
            activeMember,
          ]),
        );
        return NotificationsCubit(membersRepository: mockMembersRepository);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const NotificationsLoading(),
        NotificationsLoaded(
          expiringSoon: [expiringMember],
          expired: [expiredMemberRecent],
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as NotificationsLoaded;
        expect(state.totalCount, 2);
        expect(state.hasNotifications, isTrue);
        expect(state.expiringSoon.length, 1);
        expect(state.expired.length, 1);
        expect(state.expired.first.name, 'سارة علي');
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'emits [NotificationsLoading, NotificationsError] on stream error',
      build: () {
        when(() => mockMembersRepository.watchMembers()).thenAnswer(
          (_) => Stream.error('Database connection failed'),
        );
        return NotificationsCubit(membersRepository: mockMembersRepository);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const NotificationsLoading(),
        isA<NotificationsError>(),
      ],
    );
  });
}
