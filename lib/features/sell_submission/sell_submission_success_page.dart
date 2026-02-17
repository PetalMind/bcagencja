import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/custom_button.dart';

/// Ekran po pomyślnym wysłaniu zgłoszenia "Chcę sprzedać" – numer referencyjny, "Co dalej?", linki.
class SellSubmissionSuccessPage extends StatelessWidget {
  final String? submissionId;
  final String? email;

  const SellSubmissionSuccessPage({
    super.key,
    this.submissionId,
    this.email,
  });

  String get _referenceNumber {
    if (submissionId == null || submissionId!.isEmpty) return '—';
    return 'BC-2026-$submissionId';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Dziękujemy za zgłoszenie!',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Twoje zgłoszenie zostało przyjęte i już pracujemy nad wyceną Twojej nieruchomości.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (email != null && email!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Potwierdzenie wysłane na: $email',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      if (email != null && email!.isNotEmpty) const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.tag_rounded, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Twój numer referencyjny: $_referenceNumber',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Co dalej?',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                _nextItem('1️⃣ Za 5 minut: Email z potwierdzeniem'),
                _nextItem('2️⃣ Do 24h: Ekspert skontaktuje się z Tobą'),
                _nextItem('3️⃣ Do 48h: Otrzymasz profesjonalną wycenę'),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Podczas oczekiwania:',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go(AppRouter.oferty),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Sprawdź średnie ceny w Twoim regionie'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRouter.contact),
                  child: Row(
                    children: [
                      Icon(Icons.contact_support_rounded, size: 20, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Masz pytania? Skontaktuj się z nami'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Wróć na stronę główną',
                  onPressed: () => context.go(AppRouter.home),
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _nextItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
