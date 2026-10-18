import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/finance_repository.dart';

class GetNetProfit {
  final FinanceRepository repository;

  GetNetProfit(this.repository);

  Future<Either<Failure, double>> call(DateTime month) async {
    final result = await repository.getSummary(month);
    return result.map((s) => s.net);
  }
}
