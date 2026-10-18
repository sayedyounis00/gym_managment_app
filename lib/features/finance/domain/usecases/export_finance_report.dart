import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/finance_repository.dart';

class ExportFinanceReport {
  final FinanceRepository repository;

  ExportFinanceReport(this.repository);

  Future<Either<Failure, String>> pdf(DateTime month) {
    return repository.exportReportPdf(month);
  }

  Future<Either<Failure, String>> csv(DateTime month) {
    return repository.exportReportCsv(month);
  }
}
