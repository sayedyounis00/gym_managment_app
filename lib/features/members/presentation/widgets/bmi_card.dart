import 'package:flutter/material.dart';
import 'package:gym_managment_app/core/theme/app_colors.dart';
import 'package:gym_managment_app/core/theme/app_spacing.dart';
import 'package:gym_managment_app/core/theme/app_text_styles.dart';
import 'package:gym_managment_app/features/members/domain/entities/bmi_result.dart';

class BmiCard extends StatelessWidget {
  final BmiResult? bmi;

  const BmiCard({
    super.key,
    required this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = bmi != null;

    final badgeColor = hasData ? bmi!.category.color : AppColors.textSecondary;
    final badgeLabel = hasData ? bmi!.category.label : 'غير متوفر';
    final badgeBg = badgeColor.withValues(alpha: 0.12);

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
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'مؤشر كتلة الجسم (BMI)',
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Main Value & Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasData ? bmi!.value.toStringAsFixed(1) : '—',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasData ? badgeColor : AppColors.textSecondary,
                ),
              ),
              if (hasData) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'كجم/م²',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Hint or Muscle Disclaimer
          if (!hasData)
            Text(
              'أدخل الوزن والطول في بيانات المشترك لحساب مؤشر كتلة الجسم تلقائياً.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            const Divider(height: AppSpacing.md, thickness: 0.5, color: AppColors.border),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'مؤشر كتلة الجسم هو تقدير تقريبي وقد لا يعكس الكتلة العضلية.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
