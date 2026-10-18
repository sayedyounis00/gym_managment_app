import 'package:gym_managment_app/core/constants/app_constants.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

MemberStatusType resolveMemberStatus({
  required bool isSuspended,
  DateTime? subscriptionEndDate,
  int daysBeforeExpiry = AppConstants.expiringSoonDays,
  DateTime? now,
}) {
  if (isSuspended) {
    return MemberStatusType.paused;
  }

  if (subscriptionEndDate == null) {
    return MemberStatusType.expired;
  }

  final currentDate = now ?? DateTime.now();
  final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
  final endDay = DateTime(
    subscriptionEndDate.year,
    subscriptionEndDate.month,
    subscriptionEndDate.day,
  );

  // If today is after the end date, subscription is expired
  if (today.isAfter(endDay)) {
    return MemberStatusType.expired;
  }

  // Days left inclusive
  final differenceInDays = endDay.difference(today).inDays;
  if (differenceInDays <= daysBeforeExpiry) {
    return MemberStatusType.expiringSoon;
  }

  return MemberStatusType.active;
}
