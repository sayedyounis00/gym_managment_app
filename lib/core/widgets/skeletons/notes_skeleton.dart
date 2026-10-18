import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_spacing.dart';
import 'app_skeletonizer.dart';

/// Skeleton placeholder for the Member Notes tab.
class NotesSkeleton extends StatelessWidget {
  final int itemCount;

  const NotesSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Note Action Button skeleton
          AppSkeletonBone.card(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Bone.icon(size: 20),
                const SizedBox(width: AppSpacing.sm),
                Bone.text(width: 130, fontSize: 14),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes list skeleton
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => AppSkeletonBone.card(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Bone.circle(size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Bone.text(width: 80, fontSize: 12),
                        ],
                      ),
                      Row(
                        children: const [
                          Bone.circle(size: 24),
                          SizedBox(width: AppSpacing.xs),
                          Bone.circle(size: 24),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Bone.text(width: double.infinity, fontSize: 14),
                  const SizedBox(height: 4),
                  Bone.text(width: 200, fontSize: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
