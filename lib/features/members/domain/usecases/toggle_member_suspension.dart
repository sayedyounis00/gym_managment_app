import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/core/usecases/usecase.dart';
import '../repositories/members_repository.dart';

class ToggleSuspensionParams {
  final int memberId;
  final bool isSuspended;

  const ToggleSuspensionParams({
    required this.memberId,
    required this.isSuspended,
  });
}

class ToggleMemberSuspension implements UseCase<Unit, ToggleSuspensionParams> {
  final MembersRepository repository;

  ToggleMemberSuspension(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ToggleSuspensionParams params) {
    return repository.toggleMemberSuspension(params.memberId, params.isSuspended);
  }
}
