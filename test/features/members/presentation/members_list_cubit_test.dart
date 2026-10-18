import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';
import 'package:gym_managment_app/features/members/domain/usecases/get_members.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/members_list/members_list_cubit.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/members_list/members_list_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMembers extends Mock implements GetMembers {}

void main() {
  late MockGetMembers mockGetMembers;

  setUpAll(() {
    registerFallbackValue(const GetMembersParams());
  });

  setUp(() {
    mockGetMembers = MockGetMembers();
  });

  const testMember1 = MemberSummary(
    id: 1,
    name: 'أحمد علي',
    phone: '01012345678',
    status: MemberStatusType.active,
  );

  group('MembersListCubit Tests', () {
    test('initial state is MembersListInitial', () {
      final cubit = MembersListCubit(getMembers: mockGetMembers);
      expect(cubit.state, equals(const MembersListInitial()));
      cubit.close();
    });

    blocTest<MembersListCubit, MembersListState>(
      'emits [MembersListLoading, MembersListLoaded] on init()',
      build: () {
        when(() => mockGetMembers(any())).thenAnswer(
          (_) => Stream.value([testMember1]),
        );
        return MembersListCubit(getMembers: mockGetMembers);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const MembersListLoading(),
        const MembersListLoaded(
          members: [testMember1],
          query: '',
          filter: null,
          totalCount: 1,
        ),
      ],
    );

    blocTest<MembersListCubit, MembersListState>(
      'filters members by status filter',
      build: () {
        when(() => mockGetMembers(any())).thenAnswer(
          (_) => Stream.value([testMember1]),
        );
        return MembersListCubit(getMembers: mockGetMembers);
      },
      act: (cubit) => cubit.setFilter(MemberStatusType.active),
      expect: () => [
        const MembersListLoading(),
        const MembersListLoaded(
          members: [testMember1],
          query: '',
          filter: MemberStatusType.active,
          totalCount: 1,
        ),
      ],
    );

    blocTest<MembersListCubit, MembersListState>(
      'debounces search input by 300ms',
      build: () {
        when(() => mockGetMembers(any())).thenAnswer(
          (_) => Stream.value([testMember1]),
        );
        return MembersListCubit(getMembers: mockGetMembers);
      },
      act: (cubit) async {
        cubit.search('أحمد');
        await Future.delayed(const Duration(milliseconds: 350));
      },
      expect: () => [
        const MembersListLoading(),
        const MembersListLoaded(
          members: [testMember1],
          query: 'أحمد',
          filter: null,
          totalCount: 1,
        ),
      ],
    );
  });
}
