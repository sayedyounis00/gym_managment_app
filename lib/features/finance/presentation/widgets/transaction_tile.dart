import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/ledger_entry.dart';

class TransactionTile extends StatelessWidget {
  final LedgerEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onVoid;

  const TransactionTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == LedgerType.income;
    final isVoided = entry.isVoided;

    final primaryColor = isVoided
        ? AppColors.textDisabled
        : (isIncome ? AppColors.success : AppColors.error);

    final tintColor = isVoided
        ? AppColors.surfaceVariant
        : (isIncome ? AppColors.successTint : AppColors.errorTint);

    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : (entry.category?.icon ?? Icons.arrow_upward_rounded);

    final sign = isIncome ? '+' : '−';
    final formattedAmount = '$sign${CurrencyFormatter.format(entry.amount)}';

    final timeFormatted = DateFormat('hh:mm a', 'ar').format(entry.date);

    return InkWell(
      onTap: onTap ?? onVoid,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            // 1. Leading 40x40 icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tintColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 2. Title & Subtitle line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isVoided ? AppColors.textDisabled : AppColors.textPrimary,
                            decoration: isVoided ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVoided) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorTint,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'ملغاة',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.method != null) ...[
                        Icon(
                          entry.method!.icon,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          entry.method!.labelArabic,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (entry.method != null && entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '·',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      if (entry.subtitle != null && entry.subtitle!.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            entry.subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 3. Trailing Amount & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedAmount,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    decoration: isVoided ? TextDecoration.lineThrough : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormatted,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
