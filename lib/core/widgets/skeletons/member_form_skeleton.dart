import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import 'app_skeletonizer.dart';

/// Form skeleton placeholder for [AddEditMemberPage].
class MemberFormSkeleton extends StatelessWidget {
  const MemberFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ResponsiveCenteredContainer(
            maxWidth: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Avatar picker skeleton
                const Bone.circle(size: 100),
                const SizedBox(height: AppSpacing.sm),
                Bone.text(width: 90, fontSize: 13),
                const SizedBox(height: AppSpacing.xl),

                // Form fields skeleton
                ...List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(width: 100, fontSize: 13),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Bottom submit button bone
                Bone(
                  width: double.infinity,
                  height: 52,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
