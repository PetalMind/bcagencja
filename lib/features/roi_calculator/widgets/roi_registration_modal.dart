import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';

/// Modal zachęcający do rejestracji przed dostępem do ofert.
/// Wyświetlany po kliknięciu "Zobacz oferty" / "Zobacz podobne oferty" gdy użytkownik niezalogowany.
class RoiRegistrationModal extends StatelessWidget {
  const RoiRegistrationModal({
    super.key,
    required this.returnPath,
  });

  /// Ścieżka do przekierowania po rejestracji (np. /oferty?roiMin=6&cenaMin=...)
  final String returnPath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.accent, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Oferty dostępne dla zarejestrowanych',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bezpłatna rejestracja przez:',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('${AppRouter.rejestracja}?returnTo=${Uri.encodeComponent(returnPath)}');
              },
              icon: const Icon(Icons.business),
              label: const Text('Rejestracja firmowa (NIP)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('${AppRouter.logowanie}?returnTo=${Uri.encodeComponent(returnPath)}');
              },
              icon: const Icon(Icons.login),
              label: const Text('Mam konto – zaloguj się'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _BulletPoint(icon: Icons.check_circle_outline, text: 'Bez opłat'),
            _BulletPoint(icon: Icons.verified_user_outlined, text: 'Akceptacja NDA (ochrona danych)'),
            _BulletPoint(icon: Icons.speed, text: 'Natychmiastowy dostęp'),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Twoje parametry kalkulacji zostaną zapisane i dopasujemy oferty.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
