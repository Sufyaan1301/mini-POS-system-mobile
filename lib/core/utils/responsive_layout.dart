import 'package:flutter/material.dart';

/// Breakpoint helper supporting Mobile, Tablet Portrait, and Tablet Landscape.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tabletPortrait,
    this.tabletLandscape,
  });

  final Widget mobile;
  final Widget? tabletPortrait;
  final Widget? tabletLandscape;

  static const double tabletBreakpoint = 600;
  static const double landscapeBreakpoint = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isTabletLandscape(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= landscapeBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= landscapeBreakpoint) {
      return tabletLandscape ?? tabletPortrait ?? mobile;
    }
    if (width >= tabletBreakpoint) {
      return tabletPortrait ?? mobile;
    }
    return mobile;
  }
}
