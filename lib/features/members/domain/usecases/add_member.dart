import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import 'package:gym_managment_app/core/utils/validators.dart';
import '../repositories/members_repository.dart';

class AddMemberParams {
  final String name;
  final String phone;
  final String? photoPath;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? initialNote;

  const AddMemberParams({
    required this.name,
    required this.phone,
    this.photoPath,
    this.age,
    this.weightKg,
    this.heightCm,
    this.initialNote,
  });
}

class AddMember implements UseCase<int, AddMemberParams> {
  final MembersRepository repository;

  AddMember(this.repository);

  @override
  Future<Either<Failure, int>> call(AddMemberParams params) async {
    final nameError = FormValidators.validateName(params.name);
    if (nameError != null) {
      return Left(DatabaseFailure(nameError));
    }

    final phoneError = FormValidators.validatePhone(params.phone);
    if (phoneError != null) {
      return Left(DatabaseFailure(phoneError));
    }

    if (params.age != null) {
      final ageError = FormValidators.validateAge(params.age.toString());
      if (ageError != null) {
        return Left(DatabaseFailure(ageError));
      }
    }

    if (params.weightKg != null) {
      final weightError = FormValidators.validateWeight(params.weightKg.toString());
      if (weightError != null) {
        return Left(DatabaseFailure(weightError));
      }
    }

    if (params.heightCm != null) {
      final heightError = FormValidators.validateHeight(params.heightCm.toString());
      if (heightError != null) {
        return Left(DatabaseFailure(heightError));
      }
    }

    return repository.addMember(
      name: params.name,
      phone: params.phone,
      photoPath: params.photoPath,
      age: params.age,
      weightKg: params.weightKg,
      heightCm: params.heightCm,
      initialNote: params.initialNote,
    );
  }
}
