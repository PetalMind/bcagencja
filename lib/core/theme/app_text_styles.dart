import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Application text styles using Bai Jamjuree and Michroma fonts
class AppTextStyles {
  // Base text styles using Bai Jamjuree for body text
  static TextStyle get _baseBodyStyle => GoogleFonts.baiJamjuree(
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  // Base heading styles using Michroma for headings and CTAs
  static TextStyle get _baseHeadingStyle => GoogleFonts.michroma(
        color: AppColors.textPrimary,
        height: 1.2,
        fontWeight: FontWeight.w600,
      );
  
  // Display styles (extra large headings)
  static TextStyle get displayLarge => _baseHeadingStyle.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.bold,
      );
  
  static TextStyle get displayMedium => _baseHeadingStyle.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.bold,
      );
  
  static TextStyle get displaySmall => _baseHeadingStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );
  
  // Headline styles
  static TextStyle get headlineLarge => _baseHeadingStyle.copyWith(
        fontSize: 28,
      );
  
  static TextStyle get headlineMedium => _baseHeadingStyle.copyWith(
        fontSize: 24,
      );
  
  static TextStyle get headlineSmall => _baseHeadingStyle.copyWith(
        fontSize: 20,
      );
  
  // Title styles
  static TextStyle get titleLarge => _baseBodyStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );
  
  static TextStyle get titleMedium => _baseBodyStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  
  static TextStyle get titleSmall => _baseBodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
  
  // Body styles
  static TextStyle get bodyLarge => _baseBodyStyle.copyWith(
        fontSize: 16,
      );
  
  static TextStyle get bodyMedium => _baseBodyStyle.copyWith(
        fontSize: 14,
      );
  
  static TextStyle get bodySmall => _baseBodyStyle.copyWith(
        fontSize: 12,
      );
  
  // Label styles
  static TextStyle get labelLarge => _baseBodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );
  
  static TextStyle get labelMedium => _baseBodyStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
  
  static TextStyle get labelSmall => _baseBodyStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );
  
  // CTA (Call-to-Action) button text using Michroma
  static TextStyle get buttonLarge => _baseHeadingStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  
  static TextStyle get buttonMedium => _baseHeadingStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
  
  static TextStyle get buttonSmall => _baseHeadingStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
  
  // Price text style
  static TextStyle get priceLarge => _baseHeadingStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.price,
      );
  
  static TextStyle get priceMedium => _baseHeadingStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.price,
      );
  
  static TextStyle get priceSmall => _baseHeadingStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.price,
      );
  
  // Caption styles
  static TextStyle get caption => _baseBodyStyle.copyWith(
        fontSize: 12,
        color: AppColors.textSecondary,
      );
  
  static TextStyle get overline => _baseBodyStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );
}
