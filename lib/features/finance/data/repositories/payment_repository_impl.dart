import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart' hide Payment;
import '../../../../core/database/daos/payments_dao.dart';
import '../../../../core/database/daos/members_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentsDao paymentsDao;
  final MembersDao membersDao;
  final AppDatabase db;

  PaymentRepositoryImpl({
    required this.paymentsDao,
    required this.membersDao,
    required this.db,
  });

  @override
  Future<Either<Failure, int>> addPayment({
    required int memberId,
    int? subscriptionId,
    int? periodId,
    int? installmentId,
    required double amount,
    PaymentMethod? method,
    required DateTime paidAt,
    String? note,
  }) async {
    try {
      final member = await membersDao.getMemberById(memberId);
      final memberName = member?.name;

      final id = await db.transaction(() async {
        final paymentId = await paymentsDao.insertPayment(
          PaymentsCompanion.insert(
            memberId: memberId,
            subscriptionId: Value(subscriptionId),
            periodId: Value(periodId),
            installmentId: Value(installmentId),
            amount: amount,
            paidAt: Value(paidAt),
            paymentMethod: Value(method?.value ?? 'cash'),
            notes: Value(note),
            memberNameSnapshot: Value(memberName),
            createdAt: Value(DateTime.now()),
          ),
        );

        if (subscriptionId != null) {
          final sub = await (db.select(db.subscriptions)
                ..where((s) => s.id.equals(subscriptionId)))
              .getSingleOrNull();

          if (sub != null) {
            final newAmountPaid = sub.amountPaid + amount;
            await (db.update(db.subscriptions)
                  ..where((s) => s.id.equals(subscriptionId)))
                .write(
              SubscriptionsCompanion(
                amountPaid: Value(newAmountPaid),
              ),
            );
          }
        }

        if (periodId != null) {
          final period = await (db.select(db.subscriptionPeriods)
                ..where((p) => p.id.equals(periodId)))
              .getSingleOrNull();
          if (period != null) {
            final periodPayments = await (db.select(db.payments)
                  ..where((p) => p.periodId.equals(periodId) & p.voidedAt.isNull()))
                .get();
            final totalPaid = periodPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
            final due = period.amountDue - period.discount;
            final isFullyPaid = totalPaid >= due - 0.01;
            final status = isFullyPaid ? 'paid' : (totalPaid > 0.01 ? 'partial' : 'unpaid');

            await (db.update(db.subscriptionPeriods)
                  ..where((p) => p.id.equals(periodId)))
                .write(
              SubscriptionPeriodsCompanion(
                paymentStatus: Value(status),
                isFullyPaid: Value(isFullyPaid),
                fullyPaidAt: Value(isFullyPaid ? DateTime.now() : null),
              ),
            );
          }
        }

        return paymentId;
      });

      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('فشل تسجيل الدفعة: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> voidPayment(
    int paymentId, {
    String? reason,
  }) async {
    try {
      await db.transaction(() async {
        final payment = await paymentsDao.getPaymentById(paymentId);
        if (payment == null) {
          throw Exception('الدفعة غير موجودة');
        }

        await paymentsDao.voidPayment(paymentId, reason: reason);

        if (payment.subscriptionId != null) {
          final subPayments = await (db.select(db.payments)
                ..where((p) =>
                    p.subscriptionId.equals(payment.subscriptionId!) &
                    p.voidedAt.isNull()))
              .get();
          final totalPaid = subPayments.fold<double>(0.0, (sum, p) => sum + p.amount);

          await (db.update(db.subscriptions)
                ..where((s) => s.id.equals(payment.subscriptionId!)))
              .write(
            SubscriptionsCompanion(
              amountPaid: Value(totalPaid),
            ),
          );
        }

        if (payment.periodId != null) {
          final period = await (db.select(db.subscriptionPeriods)
                ..where((p) => p.id.equals(payment.periodId!)))
              .getSingleOrNull();
          if (period != null) {
            final periodPayments = await (db.select(db.payments)
                  ..where((p) => p.periodId.equals(payment.periodId!) & p.voidedAt.isNull()))
                .get();
            final totalPaid = periodPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
            final due = period.amountDue - period.discount;
            final isFullyPaid = totalPaid >= due - 0.01;
            final status = isFullyPaid ? 'paid' : (totalPaid > 0.01 ? 'partial' : 'unpaid');

            await (db.update(db.subscriptionPeriods)
                  ..where((p) => p.id.equals(payment.periodId!)))
                .write(
              SubscriptionPeriodsCompanion(
                paymentStatus: Value(status),
                isFullyPaid: Value(isFullyPaid),
                fullyPaidAt: Value(isFullyPaid ? period.fullyPaidAt : null),
              ),
            );
          }
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('فشل إلغاء الدفعة: $e'));
    }
  }

  @override
  Stream<List<Payment>> watchMemberPayments(int memberId) {
    return paymentsDao
        .watchPaymentsByMember(memberId)
        .map((rows) => rows.map(PaymentModel.fromDrift).toList());
  }

  @override
  Future<Either<Failure, List<Payment>>> getMemberPayments(int memberId) async {
    try {
      final rows = await paymentsDao.getPaymentsByMember(memberId);
      return Right(rows.map(PaymentModel.fromDrift).toList());
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب مدفوعات العضو: $e'));
    }
  }
}
