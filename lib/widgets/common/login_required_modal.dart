import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

/// Modal „Zaloguj się aby zobaczyć więcej” – dla GUEST przy kliknięciu w ofertę.
class LoginRequiredModal extends StatelessWidget {
  const LoginRequiredModal({
    super.key,
    this.returnTo,
  });

  /// Ścieżka powrotu po zalogowaniu (np. /property/123).
  final String? returnTo;

  static Future<void> show(BuildContext context, {String? returnTo}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginRequiredModal(returnTo: returnTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = returnTo ?? AppRouter.oferty;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Zaloguj się, aby zobaczyć więcej',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
      content: Text(
        'Pełne oferty (dokładna lokalizacja, galeria zdjęć, dane kontaktowe) są dostępne po zalogowaniu i zaakceptowaniu regulaminu oraz NDA.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('${AppRouter.logowanie}?returnTo=${Uri.encodeComponent(path)}');
          },
          icon: const Icon(Icons.login, size: 20),
          label: const Text('Zaloguj się'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}
