import 'package:equatable/equatable.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'installment.dart';

class SubscriptionPeriod extends Equatable {
  final int id;
  final int subscriptionId;
  final int periodNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double amountDue;
  final double discount;
  final String paymentStatus; // 'unpaid', 'partial', 'paid'
  final bool isFullyPaid;
  final DateTime? fullyPaidAt;
  final DateTime createdAt;
  final List<Installment> installments;

  const SubscriptionPeriod({
    required this.id,
    required this.subscriptionId,
    this.periodNumber = 1,
    required this.startDate,
    required this.endDate,
    required this.amountDue,
    this.discount = 0.0,
    this.paymentStatus = 'unpaid',
    this.isFullyPaid = false,
    this.fullyPaidAt,
    required this.createdAt,
    this.installments = const [],
  });

  /// Net amount due after applying discount
  double get netAmountDue => (amountDue - discount).clamp(0.0, double.infinity);

  /// Total amount paid across installments in this period
  double get totalPaid {
    if (installments.isNotEmpty) {
      return installments.fold<double>(
        0.0,
        (sum, item) => sum + (item.isPaid ? item.amount : item.paidAmount),
      );
    }
    return isFullyPaid ? netAmountDue : 0.0;
  }

  /// Outstanding balance for this period
  double get remainingBalance =>
      (netAmountDue - totalPaid).clamp(0.0, double.infinity);

  bool get isPaid => paymentStatus == 'paid' || isFullyPaid;
  bool get isPartial => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';

  /// Whether any pending installment is overdue
  bool hasOverdueInstallments([DateTime? now]) {
    final current = now ?? DateTime.now();
    return installments.any((inst) => inst.isOverdue(current));
  }

  /// Checks if current date falls within this period
  bool isCurrent([DateTime? now]) {
    final current = now ?? DateTime.now();
    return !current.isBefore(startDate) && !current.isAfter(endDate);
  }

  /// Days remaining in this period
  int remainingDays([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = AppDateUtils.startOfDay(current);
    final end = AppDateUtils.startOfDay(endDate);
    return end.difference(today).inDays;
  }

  SubscriptionPeriod copyWith({
    int? id,
    int? subscriptionId,
    int? periodNumber,
    DateTime? startDate,
    DateTime? endDate,
    double? amountDue,
    double? discount,
    String? paymentStatus,
    bool? isFullyPaid,
    DateTime? fullyPaidAt,
    DateTime? createdAt,
    List<Installment>? installments,
  }) {
    return SubscriptionPeriod(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      periodNumber: periodNumber ?? this.periodNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amountDue: amountDue ?? this.amountDue,
      discount: discount ?? this.discount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      fullyPaidAt: fullyPaidAt ?? this.fullyPaidAt,
      createdAt: createdAt ?? this.createdAt,
      installments: installments ?? this.installments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        periodNumber,
        startDate,
        endDate,
        amountDue,
        discount,
        paymentStatus,
        isFullyPaid,
        fullyPaidAt,
        createdAt,
        installments,
      ];
}
