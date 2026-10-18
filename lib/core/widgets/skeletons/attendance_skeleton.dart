import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_skeletonizer.dart';

/// Skeleton placeholder for the Attendance Calendar tab.
class AttendanceSkeleton extends StatelessWidget {
  const AttendanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month navigation header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Bone.circle(size: 36),
                  Bone.text(width: 120, fontSize: 16),
                  const Bone.circle(size: 36),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),

              // Weekday labels
              Row(
                children: List.generate(
                  7,
                  (_) => Expanded(
                    child: Center(
                      child: Bone.text(width: 24, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Calendar day cells grid
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: List.generate(
                  35,
                  (_) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Bone.text(width: 16, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),

              // Summary legend
              Row(
                children: [
                  const Bone.circle(size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Bone.text(width: 80, fontSize: 12),
                  const Spacer(),
                  Bone.text(width: 90, fontSize: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
