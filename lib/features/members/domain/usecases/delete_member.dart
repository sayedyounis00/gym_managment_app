import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import '../repositories/members_repository.dart';

class DeleteMember implements UseCase<Unit, int> {
  final MembersRepository repository;

  DeleteMember(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int memberId) {
    return repository.deleteMember(memberId);
  }
}
