import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'liquid_glass_effect.dart';
import 'liquid_skeleton.dart';

/// Net profit hero card skeleton with faint orange gradient and liquid glass sweep.
/// Uses [AppRadius.xl] (24dp) per design system Section 6.3.
class HeroCardSkeleton extends StatelessWidget {
  final double? netProfit;

  const HeroCardSkeleton({super.key, this.netProfit});

  @override
  Widget build(BuildContext context) {
    return LiquidSkeleton(
      enabled: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // Faint orange liquid gradient (12% primary to 8% warm tint)
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              const Color(0xFFFF8A47).withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.60),
            width: 1.0,
          ),
          boxShadow: const [LiquidGlassDecoration.softGlow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Header title & icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Bone.icon(size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'صافي الأرباح (الشهر الحالي)',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Trend delta chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+15.4%',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Big profit value
            Text(
              '18,450 ج.م',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              'الإيرادات 26,800 ج.م  ·  المصروفات 8,350 ج.م',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
