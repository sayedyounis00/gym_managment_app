import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

class Subscription extends Equatable {
  final int id;
  final int memberId;
  final int? packageId;
  final String packageNameSnapshot;
  final double priceSnapshot;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRenewal;
  final String status; // 'active', 'paused', 'expired'
  final DateTime? pausedAt;
  final String? pauseReason;
  final int totalPausedDays;
  final double amountPaid;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.memberId,
    this.packageId,
    required this.packageNameSnapshot,
    required this.priceSnapshot,
    required this.startDate,
    required this.endDate,
    this.isRenewal = false,
    this.status = 'active',
    this.pausedAt,
    this.pauseReason,
    this.totalPausedDays = 0,
    this.amountPaid = 0.0,
    required this.createdAt,
  });

  bool get isPaused => status == 'paused';
  bool get isExpired => status == 'expired';
  bool get isActive => status == 'active';

  /// Remaining unpaid balance.
  double get remainingAmount => (priceSnapshot - amountPaid).clamp(0.0, double.infinity);

  /// Derived payment status.
  PaymentStatusType get paymentStatus {
    if (amountPaid >= priceSnapshot && priceSnapshot > 0) {
      return PaymentStatusType.paid;
    } else if (amountPaid > 0) {
      return PaymentStatusType.partiallyPaid;
    } else {
      return PaymentStatusType.unpaid;
    }
  }

  /// Remaining calendar days until expiration.
  int remainingDays([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = AppDateUtils.startOfDay(current);
    final end = AppDateUtils.startOfDay(endDate);
    return end.difference(today).inDays;
  }

  /// Whether this subscription is active and within the upcoming expiration threshold.
  bool isExpiringSoon([DateTime? now, int thresholdDays = 3]) {
    if (isPaused) return false;
    final days = remainingDays(now);
    return days >= 0 && days <= thresholdDays;
  }

  /// Subscription progress (0.0 to 1.0)
  double progress([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = AppDateUtils.startOfDay(current);
    final start = AppDateUtils.startOfDay(startDate);
    final end = AppDateUtils.startOfDay(endDate);

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) {
      return today.isAfter(end) ? 1.0 : 0.0;
    }
    final daysPassed = today.difference(start).inDays;
    return (daysPassed / totalDays).clamp(0.0, 1.0);
  }

  /// Resolved MemberStatusType for UI display.
  MemberStatusType displayStatus([DateTime? now, int thresholdDays = 3]) {
    if (isPaused) {
      return MemberStatusType.paused;
    }
    final days = remainingDays(now);
    if (days < 0) {
      return MemberStatusType.expired;
    }
    if (days <= thresholdDays) {
      return MemberStatusType.expiringSoon;
    }
    return MemberStatusType.active;
  }

  Subscription copyWith({
    int? id,
    int? memberId,
    int? packageId,
    String? packageNameSnapshot,
    double? priceSnapshot,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRenewal,
    String? status,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    String? pauseReason,
    bool clearPauseReason = false,
    int? totalPausedDays,
    double? amountPaid,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      packageId: packageId ?? this.packageId,
      packageNameSnapshot: packageNameSnapshot ?? this.packageNameSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRenewal: isRenewal ?? this.isRenewal,
      status: status ?? this.status,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      pauseReason: clearPauseReason ? null : (pauseReason ?? this.pauseReason),
      totalPausedDays: totalPausedDays ?? this.totalPausedDays,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        packageId,
        packageNameSnapshot,
        priceSnapshot,
        startDate,
        endDate,
        isRenewal,
        status,
        pausedAt,
        pauseReason,
        totalPausedDays,
        amountPaid,
        createdAt,
      ];
}
