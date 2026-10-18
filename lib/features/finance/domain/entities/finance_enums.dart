import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum PaymentMethod {
  cash('cash', 'نقدي', Icons.payments_rounded),
  transfer('transfer', 'تحويل', Icons.swap_horiz_rounded),
  wallet('wallet', 'محفظة إلكترونية', Icons.account_balance_wallet_rounded);

  final String value;
  final String labelArabic;
  final IconData icon;

  const PaymentMethod(this.value, this.labelArabic, this.icon);

  static PaymentMethod? fromString(String? val) {
    if (val == null) return null;
    for (final method in PaymentMethod.values) {
      if (method.value.toLowerCase() == val.toLowerCase()) {
        return method;
      }
    }
    return PaymentMethod.cash;
  }
}

enum ExpenseCategory {
  rent('rent', 'إيجار', Icons.home_work_rounded),
  electricity('electricity', 'كهرباء', Icons.bolt_rounded),
  water('water', 'مياه', Icons.water_drop_rounded),
  maintenance('maintenance', 'صيانة', Icons.build_rounded),
  other('other', 'أخرى', Icons.more_horiz_rounded);

  final String value;
  final String labelArabic;
  final IconData icon;

  const ExpenseCategory(this.value, this.labelArabic, this.icon);

  static ExpenseCategory fromString(String val) {
    for (final cat in ExpenseCategory.values) {
      if (cat.value.toLowerCase() == val.toLowerCase()) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}

enum LedgerType {
  all('all', 'الكل'),
  income('income', 'الإيرادات'),
  expense('expense', 'المصروفات');

  final String value;
  final String labelArabic;

  const LedgerType(this.value, this.labelArabic);
}

enum PaymentStatus {
  paid('paid', 'مدفوع', AppColors.success, AppColors.successTint, Icons.check_circle_rounded),
  partial('partial', 'مدفوع جزئياً', AppColors.warning, AppColors.warningTint, Icons.schedule_rounded),
  unpaid('unpaid', 'غير مدفوع', AppColors.error, AppColors.errorTint, Icons.cancel_rounded);

  final String value;
  final String labelArabic;
  final Color color;
  final Color tintColor;
  final IconData icon;

  const PaymentStatus(
    this.value,
    this.labelArabic,
    this.color,
    this.tintColor,
    this.icon,
  );

  static PaymentStatus fromAmounts(double paid, double due) {
    if (due <= 0) return PaymentStatus.paid;
    if (paid >= due - 0.01) return PaymentStatus.paid;
    if (paid > 0.01) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  static PaymentStatus fromString(String val) {
    for (final s in PaymentStatus.values) {
      if (s.value.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return PaymentStatus.unpaid;
  }
}
