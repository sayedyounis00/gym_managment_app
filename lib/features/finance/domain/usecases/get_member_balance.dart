import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/member_balance.dart';
import '../repositories/finance_repository.dart';

class GetMemberBalance {
  final FinanceRepository repository;

  GetMemberBalance(this.repository);

  Future<Either<Failure, MemberBalance?>> call(int memberId) async {
    final result = await repository.getMembersWithBalance();
    return result.map((list) {
      return list.where((b) => b.memberId == memberId).firstOrNull;
    });
  }
}
