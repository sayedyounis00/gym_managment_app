import '../../../../core/database/daos/finance_dao.dart';
import '../../domain/entities/finance_summary.dart';

class FinanceSummaryModel {
  static FinanceSummary fromDao(MonthlySummaryRow row) {
    return FinanceSummary(
      revenue: row.revenue,
      expenses: row.expenses,
      net: row.net,
      selectedMonth: row.month,
    );
  }
}
