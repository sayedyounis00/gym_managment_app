import '../../../../core/database/daos/finance_dao.dart';
import '../../../../core/database/daos/payments_dao.dart';
import '../../../../core/database/daos/expenses_dao.dart';

abstract class FinanceLocalDataSource {
  FinanceDao get financeDao;
  PaymentsDao get paymentsDao;
  ExpensesDao get expensesDao;
}

class FinanceLocalDataSourceImpl implements FinanceLocalDataSource {
  @override
  final FinanceDao financeDao;
  @override
  final PaymentsDao paymentsDao;
  @override
  final ExpensesDao expensesDao;

  FinanceLocalDataSourceImpl({
    required this.financeDao,
    required this.paymentsDao,
    required this.expensesDao,
  });
}
