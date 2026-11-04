import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SecureBlurWrapper extends StatelessWidget {
  final Widget child;
  final bool isBlurred;
  final VoidCallback? onUnlockRequested;
  final double borderRadius;
  final String? badgeText;

  const SecureBlurWrapper({
    super.key,
    required this.child,
    required this.isBlurred,
    this.onUnlockRequested,
    this.borderRadius = AppRadius.lg,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlurred) {
      return child;
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Blurred child
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AbsorbPointer(
              absorbing: true,
              child: child,
            ),
          ),
          // Interactive lock overlay
          Positioned.fill(
            child: Material(
              color: AppColors.overlay.withValues(alpha: 0.12),
              child: InkWell(
                onTap: onUnlockRequested,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AppColors.borderStrong.withValues(alpha: 0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Flexible(
                          child: Text(
                            badgeText ?? 'محمي • انقر للفتح',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
