import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../features/finance/domain/entities/finance_enums.dart';

class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusChip({
    super.key,
    required this.status,
  });

  factory PaymentStatusChip.fromAmounts({
    required double paid,
    required double due,
  }) {
    return PaymentStatusChip(
      status: PaymentStatus.fromAmounts(paid, due),
    );
  }

  factory PaymentStatusChip.fromString(String val) {
    return PaymentStatusChip(
      status: PaymentStatus.fromString(val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: status.tintColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            status.icon,
            size: 15,
            color: status.color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.labelArabic,
            style: AppTextStyles.labelMedium.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
