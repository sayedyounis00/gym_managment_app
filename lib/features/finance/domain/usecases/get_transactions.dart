import '../entities/finance_enums.dart';
import '../entities/ledger_entry.dart';
import '../repositories/finance_repository.dart';

class GetTransactions {
  final FinanceRepository repository;

  GetTransactions(this.repository);

  Stream<List<LedgerEntry>> call({
    DateTime? from,
    DateTime? to,
    LedgerType? filter,
  }) {
    return repository.watchLedger(from: from, to: to, filter: filter);
  }
}
