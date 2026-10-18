import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/daos/dashboard_dao.dart';
import '../../../../core/utils/date_utils.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardSummaryModel> getSummary({DateTime? now});
  Stream<DashboardSummaryModel> watchSummary({DateTime? now});
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final DashboardDao dashboardDao;

  DashboardLocalDataSourceImpl({required this.dashboardDao});

  @override
  Future<DashboardSummaryModel> getSummary({DateTime? now}) async {
    final currentDate = now ?? DateTime.now();
    final (since, until) = AppDateUtils.rollingMonthWindow(currentDate);

    final results = await Future.wait([
      dashboardDao.countActiveMembers(),
      dashboardDao.countNewSubscriptions(since: since, until: until),
      dashboardDao.getExpiringSubscriptions(
        now: currentDate,
        windowDays: AppConstants.expiringSoonDays,
      ),
      dashboardDao.sumRevenue(since: since, until: until),
      dashboardDao.sumExpenses(since: since, until: until),
      dashboardDao.sumTodayRevenue(currentDate),
    ]);

    final activeCount = results[0] as int;
    final newSubsCount = results[1] as int;
    final expiringRows = results[2] as List<ExpiringSubscriptionRow>;
    final revenue = results[3] as double;
    final expenses = results[4] as double;
    final todayRevenue = results[5] as double;

    return DashboardSummaryModel.fromData(
      activeMembersCount: activeCount,
      newSubscriptionsThisMonth: newSubsCount,
      expiringRows: expiringRows,
      monthRevenue: revenue,
      monthExpenses: expenses,
      todayRevenue: todayRevenue,
    );
  }

  @override
  Stream<DashboardSummaryModel> watchSummary({DateTime? now}) {
    return dashboardDao.watchDashboardUpdates().asyncMap((_) => getSummary(now: now));
  }
}
