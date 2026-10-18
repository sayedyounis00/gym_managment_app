import 'package:equatable/equatable.dart';

class Installment extends Equatable {
  final int id;
  final int periodId;
  final int installmentNumber;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final String status; // 'pending', 'paid'
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;

  const Installment({
    required this.id,
    required this.periodId,
    this.installmentNumber = 1,
    required this.amount,
    this.paidAmount = 0.0,
    required this.dueDate,
    this.status = 'pending',
    this.paidAt,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, double.infinity);

  bool isOverdue([DateTime? now]) {
    if (isPaid) return false;
    final current = now ?? DateTime.now();
    return current.isAfter(dueDate);
  }

  Installment copyWith({
    int? id,
    int? periodId,
    int? installmentNumber,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    String? status,
    DateTime? paidAt,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
  }) {
    return Installment(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        periodId,
        installmentNumber,
        amount,
        paidAmount,
        dueDate,
        status,
        paidAt,
        paymentMethod,
        notes,
        createdAt,
      ];
}
