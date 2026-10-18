import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummary>> getSummary({DateTime? now});
  Stream<Either<Failure, DashboardSummary>> watchSummary({DateTime? now});
}
