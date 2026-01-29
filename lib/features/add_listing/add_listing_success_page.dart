import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/custom_button.dart';

/// Strona wyświetlana po pomyślnym opublikowaniu ogłoszenia.
class AddListingSuccessPage extends StatelessWidget {
  const AddListingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Ogłoszenie dodane!',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Twoje ogłoszenie zostało opublikowane i jest teraz widoczne w wyszukiwarce.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Dodaj kolejne ogłoszenie',
                  onPressed: () => context.go(AppRouter.addListing),
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Moje ogłoszenia',
                  onPressed: () => context.go(AppRouter.dashboardListings),
                  variant: ButtonVariant.outlined,
                  fullWidth: true,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Strona główna',
                  onPressed: () => context.go(AppRouter.home),
                  variant: ButtonVariant.text,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
