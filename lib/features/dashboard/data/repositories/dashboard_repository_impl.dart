import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, DashboardSummary>> getSummary({DateTime? now}) async {
    try {
      final summary = await localDataSource.getSummary(now: now);
      return Right(summary);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, DashboardSummary>> watchSummary({DateTime? now}) async* {
    try {
      yield* localDataSource
          .watchSummary(now: now)
          .map<Either<Failure, DashboardSummary>>((summary) => Right(summary))
          .handleError((error) => Left(DatabaseFailure(error.toString())));
    } catch (e) {
      yield Left(DatabaseFailure(e.toString()));
    }
  }
}
