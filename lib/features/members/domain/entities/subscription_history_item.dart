import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';

class SubscriptionHistoryItem extends Equatable {
  final int id;
  final int memberId;
  final String packageName;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final double paidAmount;
  final MemberStatusType status;
  final bool isRenewal;
  final bool trackAttendance;
  final String? paymentMethod;
  final bool isDaily;
  final bool isPayAsYouGo;
  final int attendedDaysCount;
  final double dailyRate;

  const SubscriptionHistoryItem({
    required this.id,
    required this.memberId,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.paidAmount,
    required this.status,
    this.isRenewal = false,
    this.trackAttendance = false,
    this.paymentMethod,
    this.isDaily = false,
    this.isPayAsYouGo = false,
    this.attendedDaysCount = 0,
    this.dailyRate = 0.0,
  });

  double get remainingAmount => (price - paidAmount).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
        id,
        memberId,
        packageName,
        startDate,
        endDate,
        price,
        paidAmount,
        status,
        isRenewal,
        trackAttendance,
        paymentMethod,
        isDaily,
        isPayAsYouGo,
        attendedDaysCount,
        dailyRate,
      ];
}

class PaymentHistoryItem extends Equatable {
  final int id;
  final int memberId;
  final double amount;
  final DateTime paidAt;
  final String paymentMethod;
  final String? notes;
  final DateTime? voidedAt;
  final String? voidReason;

  const PaymentHistoryItem({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.paidAt,
    required this.paymentMethod,
    this.notes,
    this.voidedAt,
    this.voidReason,
  });

  bool get isVoided => voidedAt != null;

  @override
  List<Object?> get props => [
        id,
        memberId,
        amount,
        paidAt,
        paymentMethod,
        notes,
        voidedAt,
        voidReason,
      ];
}
