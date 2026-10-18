import 'package:drift/drift.dart';
import 'package:gym_managment_app/core/database/app_database.dart';
import '../../domain/entities/subscription.dart' as domain;

class SubscriptionModel {
  static domain.Subscription fromDrift(Subscription row) {
    return domain.Subscription(
      id: row.id,
      memberId: row.memberId,
      packageId: row.packageId,
      packageNameSnapshot: row.packageNameSnapshot ?? 'باقة',
      priceSnapshot: row.priceSnapshot ?? 0.0,
      startDate: row.startDate,
      endDate: row.endDate,
      isRenewal: row.isRenewal,
      status: row.status,
      pausedAt: row.pausedAt,
      pauseReason: row.pauseReason,
      totalPausedDays: row.totalPausedDays,
      amountPaid: row.amountPaid,
      createdAt: row.createdAt,
    );
  }

  static SubscriptionsCompanion toCompanion(domain.Subscription entity) {
    return SubscriptionsCompanion(
      id: entity.id > 0 ? Value(entity.id) : const Value.absent(),
      memberId: Value(entity.memberId),
      packageId: entity.packageId != null ? Value(entity.packageId) : const Value.absent(),
      packageNameSnapshot: Value(entity.packageNameSnapshot),
      priceSnapshot: Value(entity.priceSnapshot),
      startDate: Value(entity.startDate),
      endDate: Value(entity.endDate),
      isRenewal: Value(entity.isRenewal),
      status: Value(entity.status),
      pausedAt: Value(entity.pausedAt),
      pauseReason: Value(entity.pauseReason),
      totalPausedDays: Value(entity.totalPausedDays),
      amountPaid: Value(entity.amountPaid),
      createdAt: Value(entity.createdAt),
    );
  }
}
