import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Zwarty hero na stronie głównej – tylko tytuł i podtytuł (bez wyszukiwarki).
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nieruchomości Komercyjne i Inwestycyjne',
                style: isMobile
                    ? AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.white,
                        fontSize: 22,
                      )
                    : AppTextStyles.displaySmall.copyWith(
                        color: AppColors.white,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              Text(
                'Biura • Magazyny • Hale • Działki • Inwestycje Premium',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: isMobile ? 14 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
