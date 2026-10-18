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

  factory StatusChip.paymentMethod(String method) {
    switch (method) {
      case 'wallet':
        return const StatusChip(
          label: 'محفظة إلكترونية',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.info,
          backgroundColor: AppColors.infoTint,
        );
      case 'cash':
      default:
        return const StatusChip(
          label: 'نقدي',
          icon: Icons.payments_rounded,
          color: AppColors.primaryDark,
          backgroundColor: AppColors.primaryLight,
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
