import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/expiring_subscription.dart';
import '../../../../core/database/daos/dashboard_dao.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.activeMembersCount,
    required super.newSubscriptionsThisMonth,
    required super.expiringSoon,
    required super.monthRevenue,
    required super.monthExpenses,
    super.todayRevenue = 0.0,
  });

  factory DashboardSummaryModel.fromData({
    required int activeMembersCount,
    required int newSubscriptionsThisMonth,
    required List<ExpiringSubscriptionRow> expiringRows,
    required double monthRevenue,
    required double monthExpenses,
    required double todayRevenue,
  }) {
    return DashboardSummaryModel(
      activeMembersCount: activeMembersCount,
      newSubscriptionsThisMonth: newSubscriptionsThisMonth,
      expiringSoon: expiringRows
          .map(
            (row) => ExpiringSubscription(
              memberId: row.memberId,
              memberName: row.memberName,
              phone: row.phone,
              endDate: row.endDate,
              daysLeft: row.daysLeft,
              packageName: row.packageName,
            ),
          )
          .toList(),
      monthRevenue: monthRevenue,
      monthExpenses: monthExpenses,
      todayRevenue: todayRevenue,
    );
  }
}
