import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import 'app_skeletonizer.dart';

/// Full-page skeleton placeholder for [DashboardPage].
/// Mirrors the actual dashboard component tree:
/// - Date greeting banner
/// - Responsive 2x2 or 4-column Stat cards
/// - Finance summary card with revenue/expense breakdown
/// - Expiring subscriptions list card
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= ResponsiveBreakpoints.medium;
          final isTablet = width >= ResponsiveBreakpoints.compact &&
              width < ResponsiveBreakpoints.medium;
          final isSmallPhone = width < 360;

          final statCrossAxisCount = (isDesktop || isTablet) ? 4 : 2;
          final statAspectRatio = isDesktop
              ? 1.45
              : (isTablet ? 1.4 : (isSmallPhone ? 1.15 : 1.3));

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsiveCenteredContainer(
              padding: context.responsivePagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date greeting banner skeleton
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Bone.icon(size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Bone.text(width: 140, fontSize: 13),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stat cards grid skeleton
                  GridView.count(
                    crossAxisCount: statCrossAxisCount,
                    childAspectRatio: statAspectRatio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    children: List.generate(4, (_) => const _StatCardSkeleton()),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Finance summary skeleton
                  const _FinanceSummarySkeleton(),
                  const SizedBox(height: AppSpacing.lg),

                  // Expiring subscriptions section skeleton
                  const _ExpiringSectionSkeleton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBone.card(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Bone.text(
                  words: 2,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Bone.circle(size: 36),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Bone.text(
            width: 70,
            fontSize: 24,
          ),
          const SizedBox(height: 4),
          Bone.text(
            width: 100,
            fontSize: 11,
          ),
        ],
      ),
    );
  }
}

class _FinanceSummarySkeleton extends StatelessWidget {
  const _FinanceSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBone.card(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Bone.circle(size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(width: 130, fontSize: 16),
                    const SizedBox(height: 4),
                    Bone.text(width: 90, fontSize: 12),
                  ],
                ),
              ),
              AppSkeletonBone.chip(width: 80, height: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(width: 70, fontSize: 12),
                    const SizedBox(height: 6),
                    Bone.text(width: 100, fontSize: 18),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: AppColors.border,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(width: 70, fontSize: 12),
                    const SizedBox(height: 6),
                    Bone.text(width: 100, fontSize: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpiringSectionSkeleton extends StatelessWidget {
  const _ExpiringSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBone.card(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Bone.circle(size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Bone.text(width: 150, fontSize: 15),
                ],
              ),
              AppSkeletonBone.chip(width: 60, height: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Bone.circle(size: 42),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(width: 110, fontSize: 14),
                        SizedBox(height: 4),
                        Bone.text(width: 160, fontSize: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Bone(
                    width: 58,
                    height: 24,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Bone.circle(size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
