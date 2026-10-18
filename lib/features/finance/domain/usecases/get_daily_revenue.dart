import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/finance_repository.dart';

class GetDailyRevenue {
  final FinanceRepository repository;

  GetDailyRevenue(this.repository);

  Future<Either<Failure, double>> call(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    final result = await repository.getDailyTotals(from: start, to: end);
    return result.map((list) => list.fold<double>(0.0, (sum, d) => sum + d.revenue));
  }
}
