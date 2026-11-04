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
  final bool compact;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.compact = false,
  });

  factory StatusChip.memberStatus(MemberStatusType status, {bool compact = false}) {
    switch (status) {
      case MemberStatusType.active:
        return StatusChip(
          label: 'نشط',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          backgroundColor: AppColors.successTint,
          compact: compact,
        );
      case MemberStatusType.expiringSoon:
        return StatusChip(
          label: 'ينتهي قريباً',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          backgroundColor: AppColors.warningTint,
          compact: compact,
        );
      case MemberStatusType.expired:
        return StatusChip(
          label: 'منتهي',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          backgroundColor: AppColors.errorTint,
          compact: compact,
        );
      case MemberStatusType.paused:
        return StatusChip(
          label: 'موقوف',
          icon: Icons.pause_circle_rounded,
          color: AppColors.paused,
          backgroundColor: AppColors.pausedTint,
          compact: compact,
        );
    }
  }

  factory StatusChip.paymentMethod(String method, {bool compact = false}) {
    switch (method) {
      case 'wallet':
        return StatusChip(
          label: 'محفظة إلكترونية',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.info,
          backgroundColor: AppColors.infoTint,
          compact: compact,
        );
      case 'cash':
      default:
        return StatusChip(
          label: 'نقدي',
          icon: Icons.payments_rounded,
          color: AppColors.primaryDark,
          backgroundColor: AppColors.primaryLight,
          compact: compact,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 22 : 26),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 3,
      ),
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
            size: compact ? 13 : 15,
            color: color,
          ),
          SizedBox(width: compact ? 3 : AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact ? AppTextStyles.labelSmall : AppTextStyles.labelMedium).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
