import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'skeletons/app_skeletonizer.dart';

/// Loading indicator supporting both system-designed spinner and
/// skeleton loading modes.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Widget? skeleton;

  const LoadingIndicator({
    super.key,
    this.message,
    this.skeleton,
  });

  /// Factory constructor for displaying a tailored skeleton placeholder.
  const factory LoadingIndicator.skeleton({
    Key? key,
    Widget? skeleton,
  }) = _SkeletonLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) {
      return AppSkeletonizer(
        enabled: true,
        child: skeleton!,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonLoadingIndicator extends LoadingIndicator {
  const _SkeletonLoadingIndicator({
    super.key,
    super.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) {
      return AppSkeletonizer(enabled: true, child: skeleton!);
    }

    // Default minimal skeleton card
    return AppSkeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppSkeletonBone.card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Bone.circle(size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(width: 140, fontSize: 14),
                        const SizedBox(height: 6),
                        Bone.text(width: 90, fontSize: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Bone.text(width: double.infinity, fontSize: 14),
            ],
          ),
        ),
      ),
    );
  }
}
