import 'package:flutter/material.dart';

/// Centralized Responsive System for PropZen
/// Breakpoints:
/// - Mobile: < 600px
/// - Tablet: 600px - 1024px
/// - Desktop: > 1024px
/// - Large Desktop: > 1440px
class ResponsiveLayout {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double largeDesktopBreakpoint = 1440.0;
  static const double maxContentWidth = 1280.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width <= tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > largeDesktopBreakpoint;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= tabletBreakpoint;

  static bool isMobileWidth(double width) => width < mobileBreakpoint;
  static bool isTabletWidth(double width) => width >= mobileBreakpoint && width <= tabletBreakpoint;
  static bool isDesktopWidth(double width) => width > tabletBreakpoint && width <= largeDesktopBreakpoint;
  static bool isLargeDesktopWidth(double width) => width > largeDesktopBreakpoint;

  /// Dynamic horizontal padding based on screen width
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return 16.0;
    if (width <= tabletBreakpoint) return 24.0;
    return 32.0;
  }

  /// Responsive grid column counts for property cards & listings
  static int propertyGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 1;
    if (width < 1024) return 2;
    if (width < 1440) return 3;
    return 4;
  }

  /// Responsive grid column counts for tools / feature cards
  static int featureGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) return 1;
    if (width < 800) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  /// Responsive grid column counts for admin dashboard metric cards
  static int metricCardColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 1;
    if (width < 1024) return 2;
    return 4;
  }

  /// Form column layout count
  static int formColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 768) return 1;
    return 2;
  }
}

/// Helper widget to constrain content width on large screens and center it
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveLayout.horizontalPadding(context),
      vertical: 16.0,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive Builder widget that supplies device type flags
class ResponsiveWidget extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveWidget({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final isMobile = width < ResponsiveLayout.mobileBreakpoint;
        final isTablet = width >= ResponsiveLayout.mobileBreakpoint && width <= ResponsiveLayout.tabletBreakpoint;
        final isDesktop = width > ResponsiveLayout.tabletBreakpoint;
        return builder(context, isMobile, isTablet, isDesktop);
      },
    );
  }
}
