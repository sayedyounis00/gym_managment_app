import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'fake_data.dart';
import 'liquid_glass_effect.dart';
import 'liquid_skeleton.dart';

/// Single membership package card skeleton with liquid glass shimmer.
/// Displays package name, price, duration badge, and subscribe button.
class PackageCardSkeleton extends StatelessWidget {
  final FakePackage? package;

  const PackageCardSkeleton({super.key, this.package});

  @override
  Widget build(BuildContext context) {
    final pkg = package ?? FakeData.package();

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
            // Top row: Package title & duration badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pkg.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${pkg.durationDays} يوم',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Price section
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${pkg.price.toInt()}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'ج.م',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (pkg.visitsCount != null) ...[
                  Row(
                    children: [
                      const Bone.icon(size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${pkg.visitsCount} حصة',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              pkg.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),

            // Bottom action button bone
            Bone(
              width: double.infinity,
              height: 48,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ],
        ),
      ),
    );
  }
}

/// Package list skeleton showing multiple package cards.
class PackageListSkeleton extends StatelessWidget {
  final int count;

  const PackageListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final packages = FakeData.packages(count);
    return LiquidSkeleton(
      enabled: true,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: packages.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) =>
            PackageCardSkeleton(package: packages[index]),
      ),
    );
  }
}
