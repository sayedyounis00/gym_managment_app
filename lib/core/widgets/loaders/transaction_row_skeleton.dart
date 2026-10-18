import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'fake_data.dart';
import 'liquid_skeleton.dart';

/// Single transaction row skeleton matching design system Section 9.
/// - Leading icon container 40×40 (radiusMd)
/// - Title and payment method subtitle
/// - Trailing amount and date
class TransactionRowSkeleton extends StatelessWidget {
  final FakeTransaction? transaction;

  const TransactionRowSkeleton({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    final item = transaction ?? FakeData.transaction();

    return LiquidSkeleton(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading 40×40 icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isIncome
                    ? AppColors.successTint
                    : AppColors.errorTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(child: Bone.icon(size: 20)),
            ),
            const SizedBox(width: AppSpacing.md),

            // Title and payment method
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.paymentMethod} · ${item.category}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Trailing amount and time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.isIncome ? '+' : '-'}${item.amount.toInt()} ج.م',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: item.isIncome ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '12:45 م',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDisabled,
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

/// Transaction list skeleton with sticky day header groups ("اليوم", "أمس").
class TransactionListSkeleton extends StatelessWidget {
  final Map<String, List<FakeTransaction>>? groupedTransactions;

  const TransactionListSkeleton({super.key, this.groupedTransactions});

  @override
  Widget build(BuildContext context) {
    final groups = groupedTransactions ?? FakeData.groupedTransactions();

    return LiquidSkeleton(
      enabled: true,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (context, groupIndex) {
          final groupTitle = groups.keys.elementAt(groupIndex);
          final items = groups[groupTitle]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky-day header style banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                child: Text(
                  groupTitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Group rows
              ...List.generate(
                items.length,
                (i) => Column(
                  children: [
                    TransactionRowSkeleton(transaction: items[i]),
                    if (i < items.length - 1)
                      const Divider(
                        height: 1,
                        color: AppColors.border,
                        indent: 68,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
