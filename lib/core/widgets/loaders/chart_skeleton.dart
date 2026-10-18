import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'liquid_glass_effect.dart';
import 'liquid_skeleton.dart';

/// Card skeleton displaying faint bar silhouettes of varying heights without real chart data.
/// Uses [Bone] primitives and [LiquidGlassDecoration].
class ChartSkeleton extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ChartSkeleton({
    super.key,
    this.title = 'حركة الإيرادات الأسبوعية',
    this.subtitle = 'مقارنة الأيام الـ 7 الماضية',
  });

  @override
  Widget build(BuildContext context) {
    const barHeights = [55.0, 95.0, 45.0, 110.0, 80.0, 60.0, 100.0];
    const days = ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    return LiquidSkeleton(
      enabled: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: LiquidGlassDecoration.card(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                // Legend badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'الإيرادات',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Bar silhouettes area
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Silhouette bar
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Bone(
                            width: 22,
                            height: barHeights[index],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.sm),
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Day label bone
                      Text(
                        days[index],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
