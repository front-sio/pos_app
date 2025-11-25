import 'package:flutter/material.dart';

class AppColors {
  static  Color kPrimary = const Color(0xFF2563EB); // Modern blue
  static const Color kSecondary = Color(0xFF3B82F6);
  static const Color kBackground = Color(0xFFF8FAFC);
  static const Color kScaffoldBackground = Colors.white;
  static const Color kCardBackground = Colors.white;
  static const Color kInputBackground = Color(0xFFF1F5F9);
  static const Color kSurface = Colors.white;

  // Text colors
  static const Color kText = Color(0xFF1E293B);
  static const Color kTextPrimary = Color(0xFF334155);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kTextOnPrimary = Colors.white;
  static const Color kTextLight = Color(0xFFFFFFFF);

  // Status Colors with modern palette
  static const Color kSuccess = Color(0xFF22C55E);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kError = Color(0xFFEF4444);
  static const Color kInfo = Color(0xFF3B82F6);

   static const Color kDivider = Color(0xFFE0E0E0);
  static const Color kCardShadow = Color(0x1A000000);

    static const Color kOverlayLight = Color(0x0AFFFFFF);
  static const Color kOverlayDark = Color(0x1A000000);

  // Gradient Colors
  static const List<Color> kPrimaryGradient = [
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
  ];
  
  static const List<Color> kSuccessGradient = [
    Color(0xFF10B981),
    Color(0xFF22C55E),
  ];
  
  static const List<Color> kWarningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];
  
  static const List<Color> kErrorGradient = [
    Color(0xFFDC2626),
    Color(0xFFEF4444),
  ];
  
  // Glass morphism colors
  static const Color kGlassBackground = Color(0x1AFFFFFF);
  static const Color kGlassBorder = Color(0x33FFFFFF);
  
  // Shimmer colors
  static const Color kShimmerBase = Color(0xFFE2E8F0);
  static const Color kShimmerHighlight = Color(0xFFF1F5F9);
  
  // Shadow Colors
  static const Color kShadowColor = Color(0x1A000000);

  static void updatePrimary(Color newColor) {
    kPrimary = newColor;
  }
}