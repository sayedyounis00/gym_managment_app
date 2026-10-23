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
  final VoidCallback? onDelete;
  final VoidCallback? onEndSubscription;

  const CurrentMembershipCard({
    super.key,
    required this.subscription,
    required this.status,
    required this.onRenew,
    this.onDelete,
    this.onEndSubscription,
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
    final isPayAsYouGo = sub.isPayAsYouGo;
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sub.packageName,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPayAsYouGo) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              'حسب الاستخدام (يومي)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isPayAsYouGo
                          ? (status == MemberStatusType.expired
                              ? 'من ${AppDateUtils.formatShortDate(sub.startDate)}  ←  انتهى ${AppDateUtils.formatShortDate(sub.endDate)}'
                              : 'بدأ في ${AppDateUtils.formatShortDate(sub.startDate)}  ·  مفتوح حتى الإنهاء')
                          : '${AppDateUtils.formatShortDate(sub.startDate)}  ←  ${AppDateUtils.formatShortDate(sub.endDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.memberStatus(status),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  tooltip: 'حذف الاشتراك',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isPayAsYouGo) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'أيام الحضور: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${sub.attendedDaysCount} يوم',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'سعر اليوم: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(sub.dailyRate),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المطلوب',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(sub.price),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'المدفوع',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(sub.paidAmount),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'المتبقي',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(sub.remainingAmount),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sub.remainingAmount > 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status == MemberStatusType.active &&
                onEndSubscription != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEndSubscription,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  label: const Text(
                    'إنهاء الاشتراك اليومي',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ] else ...[
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'المدفوع: ${CurrencyFormatter.format(sub.paidAmount)} / ${CurrencyFormatter.format(sub.price)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (sub.remainingAmount > 0)
                      Text(
                        'متبقي: ${CurrencyFormatter.format(sub.remainingAmount)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
