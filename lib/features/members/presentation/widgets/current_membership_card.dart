import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/core/utils/currency_formatter.dart';
import 'package:gym_managment_app/core/utils/date_utils.dart';
import 'package:gym_managment_app/core/widgets/status_chip.dart';
import 'package:gym_managment_app/features/members/domain/entities/subscription_history_item.dart';

class CurrentMembershipCard extends StatelessWidget {
  final SubscriptionHistoryItem? subscription;
  final MemberStatusType status;
  final VoidCallback onRenew;

  const CurrentMembershipCard({
    super.key,
    required this.subscription,
    required this.status,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'الاشتراك الحالي',
                  style: AppTextStyles.titleMedium,
                ),
                const Spacer(),
                StatusChip.memberStatus(status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا يوجد اشتراك نشط أو سابق لهذا المشترك.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onRenew,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('إضافة اشتراك جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sub = subscription!;
    final now = DateTime.now();
    final today = AppDateUtils.startOfDay(now);
    final start = AppDateUtils.startOfDay(sub.startDate);
    final end = AppDateUtils.startOfDay(sub.endDate);

    final totalDays = end.difference(start).inDays;
    final daysRemaining = end.difference(today).inDays;

    double progress = 0.0;
    if (totalDays > 0) {
      final daysPassed = today.difference(start).inDays;
      progress = (daysPassed / totalDays).clamp(0.0, 1.0);
    } else {
      progress = today.isAfter(end) ? 1.0 : 0.0;
    }

    Color progressColor;
    if (status == MemberStatusType.expired) {
      progressColor = AppColors.error;
    } else if (status == MemberStatusType.expiringSoon) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.packageName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${AppDateUtils.formatShortDate(sub.startDate)}  ←  ${AppDateUtils.formatShortDate(sub.endDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.memberStatus(status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                daysRemaining < 0
                    ? 'انتهى منذ ${daysRemaining.abs()} يوم'
                    : daysRemaining == 0
                        ? 'ينتهي اليوم'
                        : 'باقي $daysRemaining يوم',
                style: AppTextStyles.labelMedium.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'المدفوع: ${CurrencyFormatter.format(sub.paidAmount)} / ${CurrencyFormatter.format(sub.price)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
