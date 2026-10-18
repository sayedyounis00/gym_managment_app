import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/member_summary.dart';

/// Fake Package model for package cards and loaders.
class FakePackage {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final int? visitsCount;
  final String description;
  final bool isPopular;

  const FakePackage({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.visitsCount,
    required this.description,
    this.isPopular = false,
  });
}

/// Fake Transaction model for finance loaders.
class FakeTransaction {
  final int id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String paymentMethod;

  const FakeTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.paymentMethod,
  });
}

/// Fake Dashboard stats model.
class FakeDashboardStats {
  final int activeMembersCount;
  final int expiringSoonCount;
  final int newMembersThisMonth;
  final double netProfit;
  final double monthRevenue;
  final double monthExpenses;
  final double todayRevenue;

  const FakeDashboardStats({
    this.activeMembersCount = 142,
    this.expiringSoonCount = 7,
    this.newMembersThisMonth = 28,
    this.netProfit = 18450.0,
    this.monthRevenue = 26800.0,
    this.monthExpenses = 8350.0,
    this.todayRevenue = 1450.0,
  });
}

/// Realistic Arabic sample data generators for zero-layout-shift skeletons.
abstract final class FakeData {
  static const List<String> arabicNames = [
    'أحمد محمد علي',
    'كابتن محمود إبراهيم',
    'سارة علي حسن',
    'طارق يوسف الشريف',
    'عمر خالد منصور',
    'عبد الرحمن مصطفى',
    'نور الدين عثمان',
    'ياسين سامح إبراهيم',
  ];

  static const List<String> packageNames = [
    'اشتراك شهري شامل',
    'باقة 3 شهور لياقة',
    'باقة سنوية VIP',
    'اشتراك 12 حصة تدريب',
  ];

  static const List<String> phoneNumbers = [
    '01012345678',
    '01123456789',
    '01234567890',
    '01543219876',
  ];

  /// Returns a realistic fake [MemberSummary].
  static MemberSummary member({
    int id = 1,
    String? name,
    String? phone,
    String? packageName,
    MemberStatusType status = MemberStatusType.active,
    int daysLeft = 23,
  }) {
    return MemberSummary(
      id: id,
      name: name ?? arabicNames[(id - 1) % arabicNames.length],
      phone: phone ?? phoneNumbers[(id - 1) % phoneNumbers.length],
      packageName: packageName ?? packageNames[(id - 1) % packageNames.length],
      status: status,
      daysLeft: daysLeft,
      subscriptionEndDate: DateTime.now().add(Duration(days: daysLeft)),
    );
  }

  /// Returns a list of realistic [MemberSummary] items.
  static List<MemberSummary> members([int count = 8]) {
    final statuses = [
      MemberStatusType.active,
      MemberStatusType.expiringSoon,
      MemberStatusType.active,
      MemberStatusType.paused,
    ];
    final days = [24, 3, 45, 12, 5, 60, 2, 30];
    return List.generate(count, (index) {
      return member(
        id: index + 1,
        status: statuses[index % statuses.length],
        daysLeft: days[index % days.length],
      );
    });
  }

  /// Returns a realistic fake [FakePackage].
  static FakePackage package({
    int id = 1,
    String? name,
    double price = 650.0,
    int durationDays = 30,
  }) {
    return FakePackage(
      id: id,
      name: name ?? packageNames[(id - 1) % packageNames.length],
      price: price,
      durationDays: durationDays,
      visitsCount: 12,
      description: 'وصول غير محدود لصالة كمال الأجسام وحصص اللياقة',
      isPopular: id == 2,
    );
  }

  /// Returns a list of realistic [FakePackage] items.
  static List<FakePackage> packages([int count = 3]) {
    final prices = [450.0, 1150.0, 3800.0];
    final durations = [30, 90, 365];
    return List.generate(
      count,
      (index) => package(
        id: index + 1,
        price: prices[index % prices.length],
        durationDays: durations[index % durations.length],
      ),
    );
  }

  /// Returns a realistic [FakeTransaction].
  static FakeTransaction transaction({
    int id = 1,
    String? title,
    double amount = 650.0,
    bool isIncome = true,
    String paymentMethod = 'نقداً',
  }) {
    final titles = [
      'اشتراك باقة شهرية - أحمد محمد',
      'فاتورة كهرباء ومرافق الصالة',
      'تجديد باقة 3 شهور - سارة علي',
      'شراء مستلزمات وصيانة أجهزة',
      'اشتراك تدريب شخصي VIP',
    ];
    return FakeTransaction(
      id: id,
      title: title ?? titles[(id - 1) % titles.length],
      category: isIncome ? 'اشتراكات' : 'مصروفات تشغيل',
      amount: amount,
      isIncome: isIncome,
      date: DateTime.now().subtract(Duration(hours: id * 2)),
      paymentMethod: paymentMethod,
    );
  }

  /// Returns a grouped map of transactions by Arabic date heading.
  static Map<String, List<FakeTransaction>> groupedTransactions() {
    return {
      'اليوم (3 معاملة)': [
        transaction(
          id: 1,
          amount: 650.0,
          isIncome: true,
          paymentMethod: 'فودافون كاش',
        ),
        transaction(
          id: 2,
          amount: 250.0,
          isIncome: false,
          paymentMethod: 'نقداً',
        ),
        transaction(
          id: 3,
          amount: 1200.0,
          isIncome: true,
          paymentMethod: 'نقداً',
        ),
      ],
      'أمس (2 معاملة)': [
        transaction(
          id: 4,
          amount: 450.0,
          isIncome: true,
          paymentMethod: 'بطاقة بنكية',
        ),
        transaction(
          id: 5,
          amount: 800.0,
          isIncome: false,
          paymentMethod: 'تحويل بنكي',
        ),
      ],
    };
  }

  /// Returns fake dashboard stats.
  static FakeDashboardStats dashboardStats() => const FakeDashboardStats();
}
