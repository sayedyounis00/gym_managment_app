import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_total.dart';
import '../repositories/finance_repository.dart';

class GetDailyTotals {
  final FinanceRepository repository;

  GetDailyTotals(this.repository);

  Future<Either<Failure, List<DailyTotal>>> call({
    required DateTime from,
    required DateTime to,
  }) {
    return repository.getDailyTotals(from: from, to: to);
  }
}
