import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../entities/subscription.dart';

class ScheduleExpiryNotifications {
  final NotificationService _notificationService;

  ScheduleExpiryNotifications(this._notificationService);

  Future<Either<Failure, void>> scheduleForSubscription({
    required Subscription subscription,
    required String memberName,
    int daysBefore = 3,
  }) async {
    try {
      if (subscription.isPaused || subscription.status != 'active') {
        await _notificationService.cancelSubscriptionExpiry(subscription.id);
      } else {
        await _notificationService.scheduleSubscriptionExpiry(
          subscriptionId: subscription.id,
          memberName: memberName,
          endDate: subscription.endDate,
          daysBefore: daysBefore,
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(NotificationFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> cancelForSubscription(int subscriptionId) async {
    try {
      await _notificationService.cancelSubscriptionExpiry(subscriptionId);
      return const Right(null);
    } catch (e) {
      return Left(NotificationFailure(e.toString()));
    }
  }
}
