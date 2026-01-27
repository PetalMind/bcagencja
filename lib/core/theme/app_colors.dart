import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Primary colors from design
  static const Color primaryDark = Color(0xFF181D24);
  static const Color accent = Color(0xFFBE6E59);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Greys
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = primaryDark;
  static const Color backgroundGrey = grey50;
  
  // Text colors
  static const Color textPrimary = primaryDark;
  static const Color textSecondary = grey600;
  static const Color textDisabled = grey400;
  static const Color textOnDark = white;
  
  // Price color (accent)
  static const Color price = accent;
  
  // Border colors
  static const Color borderLight = grey200;
  static const Color borderMedium = grey300;
  static const Color borderDark = grey400;
  
  // Overlay colors
  static Color overlay = black.withOpacity(0.5);
  static Color overlayLight = black.withOpacity(0.2);
}
