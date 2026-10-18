import 'package:flutter/material.dart';

/// Screen size breakpoints following Material 3 and modern mobile-first guidelines.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compact = 600;   // Mobile phones (portrait)
  static const double medium = 900;    // Tablets, large foldables, phone landscape
  static const double expanded = 1200; // Laptops and desktops
  static const double maxContentWidth = 1200; // Max reading/dashboard width
}

/// Helper extension on [BuildContext] for responsive queries.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < ResponsiveBreakpoints.compact;
  bool get isMedium =>
      screenWidth >= ResponsiveBreakpoints.compact &&
      screenWidth < ResponsiveBreakpoints.medium;
  bool get isExpanded =>
      screenWidth >= ResponsiveBreakpoints.medium &&
      screenWidth < ResponsiveBreakpoints.expanded;
  bool get isLarge => screenWidth >= ResponsiveBreakpoints.expanded;

  bool get isTabletOrLarger => screenWidth >= ResponsiveBreakpoints.compact;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.medium;

  /// Adaptive page horizontal padding based on screen size.
  EdgeInsets get responsivePagePadding {
    if (screenWidth < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    } else if (isCompact) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    } else if (isMedium) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
  }

  /// Adaptive horizontal margin for card/section gaps.
  double get responsiveGutter {
    if (isCompact) return 12.0;
    if (isMedium) return 16.0;
    return 20.0;
  }
}

/// A wrapper that constrains the child to a max width and centers it,
/// ensuring high-end ergonomics on large tablets and desktops.
class ResponsiveCenteredContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenteredContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
