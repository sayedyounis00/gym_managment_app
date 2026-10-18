import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummary {
  final DashboardRepository repository;

  GetDashboardSummary(this.repository);

  Future<Either<Failure, DashboardSummary>> call({DateTime? now}) {
    return repository.getSummary(now: now);
  }

  Stream<Either<Failure, DashboardSummary>> watch({DateTime? now}) {
    return repository.watchSummary(now: now);
  }
}
