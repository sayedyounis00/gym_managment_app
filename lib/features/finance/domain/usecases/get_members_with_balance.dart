import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/member_balance.dart';
import '../repositories/finance_repository.dart';

class GetMembersWithBalance {
  final FinanceRepository repository;

  GetMembersWithBalance(this.repository);

  Future<Either<Failure, List<MemberBalance>>> call() {
    return repository.getMembersWithBalance();
  }
}
