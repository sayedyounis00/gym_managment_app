import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum MemberStatusType {
  active,
  expiringSoon,
  expired,
  paused,
}

enum PaymentStatusType {
  paid,
  partiallyPaid,
  unpaid,
}

class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  factory StatusChip.memberStatus(MemberStatusType status) {
    switch (status) {
      case MemberStatusType.active:
        return const StatusChip(
          label: 'نشط',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          backgroundColor: AppColors.successTint,
        );
      case MemberStatusType.expiringSoon:
        return const StatusChip(
          label: 'ينتهي قريباً',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          backgroundColor: AppColors.warningTint,
        );
      case MemberStatusType.expired:
        return const StatusChip(
          label: 'منتهي',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          backgroundColor: AppColors.errorTint,
        );
      case MemberStatusType.paused:
        return const StatusChip(
          label: 'موقوف',
          icon: Icons.pause_circle_rounded,
          color: AppColors.paused,
          backgroundColor: AppColors.pausedTint,
        );
    }
  }

  factory StatusChip.paymentStatus(PaymentStatusType status) {
    switch (status) {
      case PaymentStatusType.paid:
        return const StatusChip(
          label: 'مدفوع',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          backgroundColor: AppColors.successTint,
        );
      case PaymentStatusType.partiallyPaid:
        return const StatusChip(
          label: 'مدفوع جزئياً',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          backgroundColor: AppColors.warningTint,
        );
      case PaymentStatusType.unpaid:
        return const StatusChip(
          label: 'غير مدفوع',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          backgroundColor: AppColors.errorTint,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
