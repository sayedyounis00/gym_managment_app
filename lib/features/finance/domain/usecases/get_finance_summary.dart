import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';

class GetFinanceSummary {
  final FinanceRepository repository;

  GetFinanceSummary(this.repository);

  Future<Either<Failure, FinanceSummary>> call(DateTime month) {
    return repository.getSummary(month);
  }

  Stream<FinanceSummary> watch(DateTime month) {
    return repository.watchSummary(month);
  }
}
