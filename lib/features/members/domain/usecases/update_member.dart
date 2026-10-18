import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/core/utils/validators.dart';
import '../entities/member.dart';
import '../repositories/members_repository.dart';

class UpdateMember implements UseCase<Unit, Member> {
  final MembersRepository repository;

  UpdateMember(this.repository);

  @override
  Future<Either<Failure, Unit>> call(Member member) async {
    final nameError = FormValidators.validateName(member.name);
    if (nameError != null) {
      return Left(DatabaseFailure(nameError));
    }

    final phoneError = FormValidators.validatePhone(member.phone);
    if (phoneError != null) {
      return Left(DatabaseFailure(phoneError));
    }

    if (member.age != null) {
      final ageError = FormValidators.validateAge(member.age.toString());
      if (ageError != null) {
        return Left(DatabaseFailure(ageError));
      }
    }

    if (member.weightKg != null) {
      final weightError = FormValidators.validateWeight(member.weightKg.toString());
      if (weightError != null) {
        return Left(DatabaseFailure(weightError));
      }
    }

    if (member.heightCm != null) {
      final heightError = FormValidators.validateHeight(member.heightCm.toString());
      if (heightError != null) {
        return Left(DatabaseFailure(heightError));
      }
    }

    return repository.updateMember(member);
  }
}
