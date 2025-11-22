import 'package:flutter/material.dart';

enum ScreenSize {
  extraSmall,  // < 320px
  small,       // 320px - 480px
  medium,      // 480px - 768px
  large,       // 768px - 1024px
  extraLarge,  // 1024px - 1440px
  ultraWide    // > 1440px
}

class ResponsiveUtils {
  // Enhanced breakpoints for more granular control
  static const double extraSmallBreakpoint = 320;
  static const double smallBreakpoint = 480;
  static const double mediumBreakpoint = 768;
  static const double largeBreakpoint = 1024;
  static const double extraLargeBreakpoint = 1440;
  
  // Legacy breakpoints for backward compatibility
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get current screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < extraSmallBreakpoint) return ScreenSize.extraSmall;
    if (width < smallBreakpoint) return ScreenSize.small;
    if (width < mediumBreakpoint) return ScreenSize.medium;
    if (width < largeBreakpoint) return ScreenSize.large;
    if (width < extraLargeBreakpoint) return ScreenSize.extraLarge;
    return ScreenSize.ultraWide;
  }

  // Enhanced device type detection
  static bool isMobile(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.extraSmall || 
           screenSize == ScreenSize.small || 
           screenSize == ScreenSize.medium;
  }

  static bool isTablet(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.large;
  }

  static bool isDesktop(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.extraLarge || 
           screenSize == ScreenSize.ultraWide;
  }

  static bool isSmallScreen(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.extraSmall || 
           screenSize == ScreenSize.small;
  }

  static bool isLargeScreen(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.extraLarge || 
           screenSize == ScreenSize.ultraWide;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Enhanced responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return const EdgeInsets.all(8);
      case ScreenSize.small:
        return const EdgeInsets.all(12);
      case ScreenSize.medium:
        return const EdgeInsets.all(16);
      case ScreenSize.large:
        return const EdgeInsets.all(24);
      case ScreenSize.extraLarge:
        return const EdgeInsets.all(32);
      case ScreenSize.ultraWide:
        return const EdgeInsets.all(40);
    }
  }

  // Enhanced responsive font sizes with smooth scaling
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getScreenWidth(context);
    final scaleFactor = _calculateScaleFactor(screenWidth);
    return baseFontSize * scaleFactor;
  }

  // Calculate dynamic scale factor based on screen width
  static double _calculateScaleFactor(double screenWidth) {
    // Smooth scaling between 0.8x and 1.3x based on screen width
    const minScale = 0.8;
    const maxScale = 1.3;
    const minWidth = 280.0;
    const maxWidth = 1600.0;
    
    if (screenWidth <= minWidth) return minScale;
    if (screenWidth >= maxWidth) return maxScale;
    
    // Linear interpolation for smooth scaling
    final progress = (screenWidth - minWidth) / (maxWidth - minWidth);
    return minScale + (maxScale - minScale) * progress;
  }

  // Enhanced responsive card height with better scaling
  static double getCardHeight(BuildContext context, double baseHeight) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return baseHeight * 1.0;
      case ScreenSize.small:
        return baseHeight * 1.0;
      case ScreenSize.medium:
        return baseHeight * 1.0;
      case ScreenSize.large:
        return baseHeight * 1.1;
      case ScreenSize.extraLarge:
        return baseHeight * 1.2;
      case ScreenSize.ultraWide:
        return baseHeight * 1.3;
    }
  }

  // Enhanced responsive grid count for practice areas
  static int getPracticeAreaGridCount(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return 1;
      case ScreenSize.small:
        return 1;
      case ScreenSize.medium:
        return 2;
      case ScreenSize.large:
        return 3;
      case ScreenSize.extraLarge:
        return 4;
      case ScreenSize.ultraWide:
        return 5;
    }
  }

  // Enhanced responsive spacing with granular control
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return baseSpacing * 0.5;
      case ScreenSize.small:
        return baseSpacing * 0.7;
      case ScreenSize.medium:
        return baseSpacing * 0.9;
      case ScreenSize.large:
        return baseSpacing * 1.0;
      case ScreenSize.extraLarge:
        return baseSpacing * 1.2;
      case ScreenSize.ultraWide:
        return baseSpacing * 1.4;
    }
  }

  // Enhanced responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return baseSize * 0.8;
      case ScreenSize.small:
        return baseSize * 0.9;
      case ScreenSize.medium:
        return baseSize * 1.0;
      case ScreenSize.large:
        return baseSize * 1.1;
      case ScreenSize.extraLarge:
        return baseSize * 1.2;
      case ScreenSize.ultraWide:
        return baseSize * 1.3;
    }
  }

  // Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Enhanced responsive horizontal card width with overflow prevention
  static double getHorizontalCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    final horizontalPadding = getResponsivePadding(context).horizontal;
    final cardSpacing = getResponsiveSpacing(context, 16);
    
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        // Account for padding and spacing to prevent overflow
        return (screenWidth - horizontalPadding - cardSpacing * 2).clamp(140, screenWidth * 0.65);
      case ScreenSize.small:
        return (screenWidth - horizontalPadding - cardSpacing * 2).clamp(160, screenWidth * 0.7);
      case ScreenSize.medium:
        return 180;
      case ScreenSize.large:
        return 220;
      case ScreenSize.extraLarge:
        return 260;
      case ScreenSize.ultraWide:
        return 300;
    }
  }

  // Enhanced responsive wrap spacing
  static double getWrapSpacing(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return 4;
      case ScreenSize.small:
        return 6;
      case ScreenSize.medium:
        return 8;
      case ScreenSize.large:
        return 10;
      case ScreenSize.extraLarge:
        return 12;
      case ScreenSize.ultraWide:
        return 16;
    }
  }

  // Dynamic button height based on screen size
  static double getButtonHeight(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return 40;
      case ScreenSize.small:
        return 44;
      case ScreenSize.medium:
        return 48;
      case ScreenSize.large:
        return 52;
      case ScreenSize.extraLarge:
        return 56;
      case ScreenSize.ultraWide:
        return 60;
    }
  }

  // Dynamic border radius based on screen size
  static double getBorderRadius(BuildContext context, double baseRadius) {
    final scaleFactor = _calculateScaleFactor(getScreenWidth(context));
    return baseRadius * scaleFactor;
  }

  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context, {double? horizontal, double? vertical}) {
    final basePadding = getResponsivePadding(context).horizontal / 2;
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? basePadding,
      vertical: vertical ?? basePadding * 0.75,
    );
  }

  // Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context, {
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    final screenWidth = getScreenWidth(context);
    final screenHeight = getScreenHeight(context);
    
    return BoxConstraints(
      minWidth: minWidth ?? 0,
      maxWidth: maxWidth ?? screenWidth * 0.9,
      minHeight: minHeight ?? 0,
      maxHeight: maxHeight ?? screenHeight * 0.8,
    );
  }

  // Get responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return _calculateScaleFactor(getScreenWidth(context));
  }

  // Get responsive elevation
  static double getResponsiveElevation(BuildContext context, double baseElevation) {
    switch (getScreenSize(context)) {
      case ScreenSize.extraSmall:
        return baseElevation * 0.5;
      case ScreenSize.small:
        return baseElevation * 0.7;
      case ScreenSize.medium:
        return baseElevation;
      case ScreenSize.large:
        return baseElevation * 1.1;
      case ScreenSize.extraLarge:
        return baseElevation * 1.2;
      case ScreenSize.ultraWide:
        return baseElevation * 1.3;
    }
  }

  // Get responsive aspect ratio
  static double getResponsiveAspectRatio(BuildContext context, double baseRatio) {
    if (isLandscape(context)) {
      return baseRatio * 1.2; // Wider aspect ratio in landscape
    }
    return baseRatio;
  }

  // Standardized method names for consistency
  static double getSpacing(BuildContext context, double baseSpacing) {
    return getResponsiveSpacing(context, baseSpacing);
  }

  static double getFontSize(BuildContext context, double baseFontSize) {
    return getResponsiveFontSize(context, baseFontSize);
  }

  static double getIconSize(BuildContext context, double baseSize) {
    return getResponsiveIconSize(context, baseSize);
  }
}