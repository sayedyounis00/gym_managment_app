class AppRoutes {
  static const String dashboard = '/';
  static const String members = '/members';
  static const String addMember = '/members/new';
  static const String memberDetails = '/members/:id';
  static const String editMember = '/members/:id/edit';
  static const String memberships = '/memberships';
  static const String addPackage = '/memberships/package/new';
  static const String editPackage = '/memberships/package/:id/edit';
  static const String finance = '/finance';
  static const String addExpense = '/finance/expense/new';
  static const String addPayment = '/finance/payment/new';
  static const String financeReports = '/finance/reports';
  static const String settings = '/settings';
  static const String backup = '/settings/backup';

  static String membersWithStatus(String status) => '/members?status=$status';
  static String memberDetailsPath(int id) => '/members/$id';
  static String editMemberPath(int id) => '/members/$id/edit';
  static String editPackagePath(int id) => '/memberships/package/$id/edit';
}
