import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import 'app_skeletonizer.dart';

/// Full-page skeleton placeholder for [MembersPage].
/// Mirrors the actual members list layout:
/// - Optional search bar and filter chips header (when [showHeader] is true)
/// - List of member tiles with avatar, details, badge, and action button
class MembersListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showHeader;

  const MembersListSkeleton({
    super.key,
    this.itemCount = 8,
    this.showHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final listWidget = ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) => const _MemberTileSkeleton(),
    );

    if (!showHeader) {
      return AppSkeletonizer(
        enabled: true,
        child: ResponsiveCenteredContainer(
          maxWidth: ResponsiveBreakpoints.maxContentWidth,
          child: listWidget,
        ),
      );
    }

    return AppSkeletonizer(
      enabled: true,
      child: Column(
        children: [
          // Search & Filter header skeleton
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: ResponsiveCenteredContainer(
              maxWidth: ResponsiveBreakpoints.maxContentWidth,
              child: Column(
                children: [
                // Search bar bone
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      const Bone.icon(size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Bone.text(width: 140, fontSize: 14),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Filter chips bone row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Bone(
                          width: index == 0 ? 64 : 88,
                          height: 32,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Member items list skeleton
          Expanded(
            child: ResponsiveCenteredContainer(
              maxWidth: ResponsiveBreakpoints.maxContentWidth,
              child: listWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTileSkeleton extends StatelessWidget {
  const _MemberTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Bone.circle(size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Bone.text(
                        words: 3,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Bone(
                      width: 50,
                      height: 22,
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.full)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Bone.text(
                  width: 170,
                  fontSize: 12,
                ),
                const SizedBox(height: 4),
                Bone.text(
                  width: 130,
                  fontSize: 11,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Bone.circle(size: 36),
        ],
      ),
    );
  }
}
