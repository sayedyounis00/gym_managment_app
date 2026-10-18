import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'liquid_glass_effect.dart';

/// Single source-of-truth skeleton wrapper delivering the translucent
/// liquid glass aesthetic.
/// - Wraps [Skeletonizer] with [LiquidGlassEffect]
/// - Containers color set to [AppColors.surface]
/// - 250ms easeOutCubic switch cross-fade
/// - Accessibility: Live region announce 'جاري التحميل'
class LiquidSkeleton extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool ignoreContainers;

  const LiquidSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
    this.ignoreContainers = false,
  });

  /// Canonical [SkeletonizerConfigData] using [LiquidGlassEffect].
  static SkeletonizerConfigData get config => const SkeletonizerConfigData(
    effectResolver: _resolveEffect,
    containersColor: AppColors.surface,
    textBorderRadius: TextBoneBorderRadius(
      BorderRadius.all(Radius.circular(AppRadius.sm)),
      borderShape: TextBoneBorderShape.roundedSuperellipse,
    ),
    justifyMultiLineText: true,
    ignoreContainers: false,
    enableSwitchAnimation: true,
    switchAnimationConfig: SwitchAnimationConfig(
      duration: Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
    ),
  );

  static PaintingEffect _resolveEffect(Brightness _) =>
      const LiquidGlassEffect();

  @override
  Widget build(BuildContext context) {
    Widget skeleton = Skeletonizer(
      enabled: enabled,
      effect: const LiquidGlassEffect(),
      containersColor: AppColors.surface,
      textBoneBorderRadius: const TextBoneBorderRadius(
        BorderRadius.all(Radius.circular(AppRadius.sm)),
        borderShape: TextBoneBorderShape.roundedSuperellipse,
      ),
      justifyMultiLineText: true,
      ignoreContainers: ignoreContainers,
      enableSwitchAnimation: true,
      switchAnimationConfig: const SwitchAnimationConfig(
        duration: Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
      ),
      child: child,
    );

    if (enabled) {
      skeleton = Semantics(
        label: 'جاري التحميل',
        liveRegion: true,
        child: skeleton,
      );
    }

    return skeleton;
  }
}
