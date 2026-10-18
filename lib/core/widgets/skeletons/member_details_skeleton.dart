import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import 'app_skeletonizer.dart';

/// Full-page skeleton placeholder for [MemberDetailsPage].
/// Mirrors the comprehensive member details layout:
/// - Profile header card (80px avatar, name, phone, status, action buttons)
/// - Active membership hero card with progress bar and expiry chips
/// - Body stats metric card (weight, height, fat percentage)
/// - Tab section skeleton (Subscriptions / Attendance / Payments / Notes)
class MemberDetailsSkeleton extends StatelessWidget {
  const MemberDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenteredContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header profile card skeleton
              AppSkeletonBone.card(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Bone.circle(size: 80),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Bone.text(
                                      words: 2,
                                      fontSize: 18,
                                    ),
                                  ),
                                  AppSkeletonBone.chip(width: 58, height: 24),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Bone.text(width: 110, fontSize: 13),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Bone(
                                    width: 70,
                                    height: 30,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Bone(
                                    width: 80,
                                    height: 30,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Active Membership Hero Card skeleton
              AppSkeletonBone.card(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: 140, fontSize: 16),
                            const SizedBox(height: 4),
                            Bone.text(width: 90, fontSize: 12),
                          ],
                        ),
                        AppSkeletonBone.chip(width: 68, height: 26),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Progress bar bone
                    const Bone(
                      height: 8,
                      width: double.infinity,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3-metric info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        3,
                        (_) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: 50, fontSize: 11),
                            const SizedBox(height: 4),
                            Bone.text(width: 70, fontSize: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Body Stats Card skeleton
              AppSkeletonBone.card(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Bone.text(width: 120, fontSize: 14),
                        const Bone.icon(size: 18),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: index < 2 ? AppSpacing.sm : 0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              children: [
                                Bone.text(width: 40, fontSize: 11),
                                const SizedBox(height: 4),
                                Bone.text(width: 50, fontSize: 15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tab Bar skeleton
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: List.generate(
                    4,
                    (_) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: 4,
                        ),
                        child: Center(child: Bone.text(width: 55, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Tab Content skeleton cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => AppSkeletonBone.card(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Bone.circle(size: 38),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: 120, fontSize: 14),
                            const SizedBox(height: 4),
                            Bone.text(width: 80, fontSize: 11),
                          ],
                        ),
                      ),
                      AppSkeletonBone.chip(width: 60, height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
