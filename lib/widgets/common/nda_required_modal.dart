import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

/// Modal „Zaakceptuj NDA aby zobaczyć pełne oferty” – dla INVESTOR_BASIC.
class NdaRequiredModal extends StatelessWidget {
  const NdaRequiredModal({
    super.key,
    this.returnTo,
  });

  /// Ścieżka powrotu po weryfikacji (np. /property/123).
  final String? returnTo;

  static Future<void> show(BuildContext context, {String? returnTo}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NdaRequiredModal(returnTo: returnTo),
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
          Icon(Icons.verified_user_outlined, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Zaakceptuj NDA, aby zobaczyć pełne oferty',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
      content: Text(
        'Masz konto, ale pełne oferty (dokładna lokalizacja, galeria, dane kontaktowe) wymagają akceptacji regulaminu oraz umowy o poufności (NDA).',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Później'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('${AppRouter.weryfikacja}?returnTo=${Uri.encodeComponent(path)}');
          },
          icon: const Icon(Icons.verified_user, size: 20),
          label: const Text('Dokończ weryfikację (NDA)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}
