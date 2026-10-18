import 'package:gym_managment_app/core/utils/date_utils.dart';
import '../entities/subscription.dart';

abstract final class MembershipRules {
  /// Pure date calculation for end date.
  /// Months use calendar month addition clamped to the last day of the target month.
  static DateTime calculateEndDate({
    required DateTime startDate,
    required int durationValue,
    required String durationUnit, // 'days' | 'months'
  }) {
    if (durationUnit == 'months') {
      final totalMonths = startDate.month + durationValue;
      final targetYear = startDate.year + ((totalMonths - 1) ~/ 12);
      final targetMonth = ((totalMonths - 1) % 12) + 1;
      final maxDayInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final targetDay = startDate.day > maxDayInTargetMonth ? maxDayInTargetMonth : startDate.day;

      return DateTime(
        targetYear,
        targetMonth,
        targetDay,
        startDate.hour,
        startDate.minute,
        startDate.second,
      );
    } else {
      return startDate.add(Duration(days: durationValue));
    }
  }

  /// Calculates the default start date for a renewal.
  /// If the member has an active, non-expired subscription, starts the day after current end date.
  /// Otherwise, starts today.
  static DateTime calculateRenewStartDate({
    Subscription? currentSubscription,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = AppDateUtils.startOfDay(current);

    if (currentSubscription != null &&
        currentSubscription.isActive &&
        !currentSubscription.endDate.isBefore(today)) {
      final endDay = AppDateUtils.startOfDay(currentSubscription.endDate);
      return endDay.add(const Duration(days: 1));
    }

    return today;
  }

  /// Applies pause logic to an active subscription.
  /// Throws [ArgumentError] if subscription is not active or already expired.
  static Subscription applyPause({
    required Subscription subscription,
    required DateTime pauseDate,
    String? reason,
  }) {
    if (subscription.status != 'active') {
      throw StateError('لا يمكن إيقاف اشتراك غير نشط');
    }
    final today = AppDateUtils.startOfDay(pauseDate);
    final end = AppDateUtils.startOfDay(subscription.endDate);
    if (end.isBefore(today)) {
      throw StateError('لا يمكن إيقاف اشتراك منتهي بالفعل');
    }

    return subscription.copyWith(
      status: 'paused',
      pausedAt: pauseDate,
      pauseReason: reason,
    );
  }

  /// Applies resume logic to a paused subscription.
  /// Shifts [endDate] by the number of paused days and updates [totalPausedDays].
  static Subscription applyResume({
    required Subscription subscription,
    required DateTime resumeDate,
  }) {
    if (subscription.status != 'paused' || subscription.pausedAt == null) {
      throw StateError('الاشتراك غير موقوف');
    }

    final pausedDay = AppDateUtils.startOfDay(subscription.pausedAt!);
    final resumeDay = AppDateUtils.startOfDay(resumeDate);
    var shiftDays = resumeDay.difference(pausedDay).inDays;
    if (shiftDays < 0) shiftDays = 0;

    final newEndDate = subscription.endDate.add(Duration(days: shiftDays));
    final newTotalPausedDays = subscription.totalPausedDays + shiftDays;

    return subscription.copyWith(
      status: 'active',
      endDate: newEndDate,
      pausedAt: null,
      pauseReason: null,
      totalPausedDays: newTotalPausedDays,
    );
  }
}
