import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A custom [PaintingEffect] producing a soft, translucent liquid glass appearance:
/// - Semi-transparent frosted glass base (secondaryLight @ 45% blended toward surface)
/// - Fluid 20° diagonal light sweep using Curves.easeInOutSine
/// - Subtle warm primary tint in the core of the sweep
/// - Full RTL mirroring awareness (sweep travels in reading direction)
/// - Static fallback when [disableAnimations] is active
class LiquidGlassEffect extends PaintingEffect {
  /// Directional start alignment for the 20° diagonal sweep.
  final AlignmentGeometry begin;

  /// Directional end alignment for the 20° diagonal sweep.
  final AlignmentGeometry end;

  const LiquidGlassEffect({
    super.duration = const Duration(milliseconds: 1600),
    super.lowerBound = -0.6,
    super.upperBound = 1.6,
    super.reverse = false,
    this.begin = const AlignmentDirectional(-1.0, -0.36),
    this.end = const AlignmentDirectional(1.0, 0.36),
  });

  /// Computes the semi-transparent frosted base glass color.
  Color get baseColor {
    return Color.lerp(
      AppColors.surface,
      AppColors.secondaryLight,
      0.45,
    )!.withValues(alpha: 0.50);
  }

  /// Highlight gradient colors with subtle warm gym-orange tint at the core.
  List<Color> get colors {
    final base = baseColor;
    const highlight55 = Color(0x8CFFFFFF); // white @ 55%
    const highlight85 = Color(0xD9FFFFFF); // white @ 85% sharp core

    // Subtle 18% primaryLight warm liquid accent
    final warmTint = Color.alphaBlend(
      AppColors.primaryLight.withValues(alpha: 0.18),
      base,
    );
    final core = Color.alphaBlend(highlight85, warmTint);

    return [
      base,
      Color.alphaBlend(highlight55, base),
      core,
      Color.alphaBlend(highlight55, base),
      base,
    ];
  }

  /// Stops along the diagonal sweep for a focused liquid shimmer core.
  List<double> get stops => const [0.0, 0.45, 0.50, 0.55, 1.0];

  @override
  ui.Paint createPaint(double t, ui.Rect rect, TextDirection? textDirection) {
    final disableAnimations = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    final double effectiveOffset;
    if (disableAnimations) {
      // Park sweep far off-screen so static glass base is rendered
      effectiveOffset = -3.0;
    } else {
      // Fluid easeInOutSine curve across the cycle
      final rawProgress = ((t - lowerBound) / (upperBound - lowerBound)).clamp(
        0.0,
        1.0,
      );
      final curvedProgress = Curves.easeInOutSine.transform(rawProgress);
      effectiveOffset =
          lowerBound + (curvedProgress * (upperBound - lowerBound));
    }

    return ui.Paint()
      ..shader = LinearGradient(
        colors: colors,
        stops: stops,
        begin: begin,
        end: end,
        tileMode: TileMode.clamp,
        transform: _LiquidGlassGradientTransform(offset: effectiveOffset),
      ).createShader(rect, textDirection: textDirection);
  }

  @override
  PaintingEffect lerp(PaintingEffect? other, double t) {
    if (other is LiquidGlassEffect) {
      return LiquidGlassEffect(
        duration: duration,
        begin: AlignmentGeometry.lerp(begin, other.begin, t)!,
        end: AlignmentGeometry.lerp(end, other.end, t)!,
      );
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassEffect &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          begin == other.begin &&
          end == other.end;

  @override
  int get hashCode => Object.hash(duration, begin, end);
}

/// RTL-aware sliding gradient transform that moves along reading direction.
class _LiquidGlassGradientTransform extends GradientTransform {
  final double offset;

  const _LiquidGlassGradientTransform({required this.offset});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // In RTL, flip horizontal offset so sweep travels from right to left (reading direction)
    final isRtl = textDirection == TextDirection.rtl;
    final resolvedOffset = isRtl ? -offset : offset;
    return Matrix4.translationValues(bounds.width * resolvedOffset, 0.0, 0.0);
  }
}

/// Glass rim and soft depth decorations for cards and bones.
abstract final class LiquidGlassDecoration {
  /// Subtle blur-free shadow (0 2 8 rgba(27,33,48,.04)).
  static const BoxShadow softGlow = BoxShadow(
    color: Color(0x0A1B2130),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  /// Card glass rim with 1px border and soft depth.
  static BoxDecoration card({BorderRadius? borderRadius, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.60),
        width: 1.0,
      ),
      boxShadow: const [softGlow],
    );
  }

  /// Bone glass rim with crisp glass depth.
  static BoxDecoration bone({
    BorderRadius? borderRadius,
    bool isCircle = false,
  }) {
    if (isCircle) {
      return BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xB3FFFFFF), width: 1.0),
        boxShadow: const [softGlow],
      );
    }
    return BoxDecoration(
      color: AppColors.secondaryLight.withValues(alpha: 0.45),
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.60),
        width: 1.0,
      ),
      boxShadow: const [softGlow],
    );
  }
}
