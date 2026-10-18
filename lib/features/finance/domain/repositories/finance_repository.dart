import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_total.dart';
import '../entities/finance_enums.dart';
import '../entities/finance_summary.dart';
import '../entities/ledger_entry.dart';
import '../entities/member_balance.dart';

abstract class FinanceRepository {
  Stream<FinanceSummary> watchSummary(DateTime month);
  Future<Either<Failure, FinanceSummary>> getSummary(DateTime month);
  Stream<List<LedgerEntry>> watchLedger({
    DateTime? from,
    DateTime? to,
    LedgerType? filter,
  });
  Future<Either<Failure, List<DailyTotal>>> getDailyTotals({
    required DateTime from,
    required DateTime to,
  });
  Future<Either<Failure, List<MemberBalance>>> getMembersWithBalance();
  Future<Either<Failure, String>> exportReportPdf(DateTime month);
  Future<Either<Failure, String>> exportReportCsv(DateTime month);
}
