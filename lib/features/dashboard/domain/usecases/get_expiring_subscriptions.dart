import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expiring_subscription.dart';
import '../repositories/dashboard_repository.dart';

class GetExpiringSubscriptions {
  final DashboardRepository repository;

  GetExpiringSubscriptions(this.repository);

  Future<Either<Failure, List<ExpiringSubscription>>> call({DateTime? now}) async {
    final result = await repository.getSummary(now: now);
    return result.map((summary) => summary.expiringSoon);
  }
}
