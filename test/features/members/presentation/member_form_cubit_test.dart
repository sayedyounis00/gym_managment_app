import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/services/image_storage_service.dart';
import 'package:gym_managment_app/features/members/domain/entities/gender.dart';
import 'package:gym_managment_app/features/members/domain/entities/member.dart';
import 'package:gym_managment_app/features/members/domain/repositories/members_repository.dart';
import 'package:gym_managment_app/features/members/domain/usecases/add_member.dart';
import 'package:gym_managment_app/features/members/domain/usecases/update_member.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/member_form/member_form_cubit.dart';
import 'package:gym_managment_app/features/members/presentation/cubit/member_form/member_form_state.dart';
import 'package:mocktail/mocktail.dart';

class MockMembersRepository extends Mock implements MembersRepository {}
class MockAddMember extends Mock implements AddMember {}
class MockUpdateMember extends Mock implements UpdateMember {}
class MockImageStorageService extends Mock implements ImageStorageService {}

void main() {
  late MockMembersRepository mockRepository;
  late MockAddMember mockAddMember;
  late MockUpdateMember mockUpdateMember;
  late MockImageStorageService mockImageService;
  late MemberFormCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const AddMemberParams(
        name: 'test',
        phone: '01012345678',
        gender: Gender.male,
      ),
    );
    registerFallbackValue(
      Member(
        id: 1,
        name: 'test',
        phone: '01012345678',
        gender: Gender.male,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockMembersRepository();
    mockAddMember = MockAddMember();
    mockUpdateMember = MockUpdateMember();
    mockImageService = MockImageStorageService();

    cubit = MemberFormCubit(
      membersRepository: mockRepository,
      addMember: mockAddMember,
      updateMember: mockUpdateMember,
      imageStorageService: mockImageService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('MemberFormCubit Gender Tests', () {
    test('updateGender sets gender and marks form as dirty', () {
      cubit.init();
      cubit.updateGender(Gender.female);

      final state = cubit.state as MemberFormEditing;
      expect(state.gender, equals(Gender.female));
      expect(state.isDirty, isTrue);
    });

    blocTest<MemberFormCubit, MemberFormState>(
      'requires gender on new members during save',
      build: () => cubit,
      act: (cubit) async {
        await cubit.init();
        cubit.updateName('أحمد علي');
        cubit.updatePhone('01012345678');
        // Do not set gender
        await cubit.save();
      },
      verify: (cubit) {
        final state = cubit.state as MemberFormEditing;
        expect(state.errors.containsKey('gender'), isTrue);
        expect(state.errors['gender'], equals('يرجى تحديد الجنس'));
      },
    );

    blocTest<MemberFormCubit, MemberFormState>(
      'saves successfully when valid name, phone, and gender are provided',
      build: () {
        when(() => mockAddMember(any())).thenAnswer((_) async => const Right(10));
        return cubit;
      },
      act: (cubit) async {
        await cubit.init();
        cubit.updateName('سارة أحمد');
        cubit.updatePhone('01011112222');
        cubit.updateGender(Gender.female);
        await cubit.save();
      },
      verify: (cubit) {
        expect(cubit.state, equals(const MemberFormSaved(memberId: 10, isEdit: false)));
        verify(() => mockAddMember(any(that: isA<AddMemberParams>().having((p) => p.gender, 'gender', Gender.female)))).called(1);
      },
    );
  });
}
