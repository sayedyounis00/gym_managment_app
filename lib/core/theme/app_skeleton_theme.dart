import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/loaders/liquid_glass_effect.dart';
import '../widgets/loaders/liquid_skeleton.dart';

/// Central theme configuration for [Skeletonizer] loading states.
/// Unified with [LiquidSkeleton.config] to maintain a single source of truth.
abstract final class AppSkeletonTheme {
  /// Default translucent liquid glass effect.
  static const LiquidGlassEffect liquidEffect = LiquidGlassEffect();

  /// Global [SkeletonizerConfigData] providing consistent liquid glass behavior.
  static SkeletonizerConfigData get config => LiquidSkeleton.config;
}
