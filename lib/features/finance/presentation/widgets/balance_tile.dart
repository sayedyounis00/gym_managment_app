import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/member_balance.dart';

class BalanceTile extends StatelessWidget {
  final MemberBalance balance;
  final VoidCallback onTap;

  const BalanceTile({
    super.key,
    required this.balance,
    required this.onTap,
  });

  Future<void> _callMember(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            // 1. Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.errorTint,
              backgroundImage: balance.memberAvatarUrl != null
                  ? NetworkImage(balance.memberAvatarUrl!)
                  : null,
              child: balance.memberAvatarUrl == null
                  ? Text(
                      balance.memberName.isNotEmpty ? balance.memberName[0] : '؟',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm + 2),

            // 2. Name & package
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    balance.memberName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (balance.activePackageName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      balance.activePackageName!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // 3. Outstanding remaining amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(balance.remaining),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'مستحق',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),

            // 4. Call shortcut button (Default: yes, call icon only per Open Question 1)
            IconButton(
              icon: const Icon(
                Icons.phone_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              tooltip: 'اتصال بالمشترك',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _callMember(balance.memberPhone),
            ),
          ],
        ),
      ),
    );
  }
}
