import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';

/// Ekran sukcesu po rejestracji NIP – informacja o wysłanym linku weryfikacyjnym.
class RegistrationNipSuccessPage extends ConsumerWidget {
  const RegistrationNipSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AppBarCustom(showBackButton: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Konto utworzone',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Na podany adres e-mail wysłaliśmy link weryfikacyjny. '
                'Potwierdź e-mail w ciągu 24 h, aby uzyskać pełny dostęp do ofert.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: () => context.go(AppRouter.logowanie),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('Przejdź do logowania'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.go(AppRouter.rejestracja),
                child: Text(
                  'Wróć do rejestracji',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
