import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A system-designed wrapper around [Skeletonizer].
/// Ensures standard animations, container colors, and RTL awareness.
class AppSkeletonizer extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool ignoreContainers;

  const AppSkeletonizer({
    super.key,
    required this.child,
    this.enabled = true,
    this.ignoreContainers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      ignoreContainers: ignoreContainers,
      child: child,
    );
  }
}

/// System design compliant skeleton bone helper primitives.
abstract final class AppSkeletonBone {
  /// Circular bone for avatars, icon buttons, and circular badges.
  static Widget circle({double size = 48}) {
    return Bone.circle(size: size);
  }

  /// Rounded rectangular bone for text lines, numbers, or headers.
  static Widget textLine({
    double width = double.infinity,
    double height = 14,
    double radius = AppRadius.sm,
  }) {
    return Bone(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Pill/chip shaped bone for status chips, filter buttons, and action tags.
  static Widget chip({
    double width = 72,
    double height = 30,
  }) {
    return Bone(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppRadius.full),
    );
  }

  /// Card/Container bone matching the app's CardTheme shape and border.
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}
