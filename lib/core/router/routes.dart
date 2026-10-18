class AppRoutes {
  static const String dashboard = '/';
  static const String members = '/members';
  static const String addMember = '/members/new';
  static const String memberDetails = '/members/:id';
  static const String editMember = '/members/:id/edit';
  static const String memberships = '/memberships';
  static const String finance = '/finance';
  static const String settings = '/settings';

  static String membersWithStatus(String status) => '/members?status=$status';
  static String memberDetailsPath(int id) => '/members/$id';
  static String editMemberPath(int id) => '/members/$id/edit';
}
