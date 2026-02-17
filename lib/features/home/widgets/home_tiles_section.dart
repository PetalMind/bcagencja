import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';

/// Trzy główne kafle na stronie głównej: Inwestor, Chcę sprzedać, Kalkulator ROI.
class HomeTilesSection extends StatelessWidget {
  const HomeTilesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, AppSpacing.containerMaxWidth);
        final padding = EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
          vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        );
        return Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: maxWidth,
              child: isMobile
                  ? _buildColumnLayout(context)
                  : _buildGridLayout(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeTile(
          icon: Icons.trending_up_rounded,
          title: 'Jestem Inwestorem',
          subtitle: 'Baza ofert (teasery). Logowanie (LinkedIn/NIP) → NDA → dostęp do pełnych danych i VDR.',
          ctaLabel: 'Zobacz oferty',
          onTap: () => context.go(AppRouter.oferty),
        ),
        const SizedBox(height: AppSpacing.lg),
        _HomeTile(
          icon: Icons.real_estate_agent_rounded,
          title: 'Chcę sprzedać nieruchomość / grunt',
          subtitle: 'Zgłoś swoją nieruchomość – skontaktujemy się i zaproponujemy dalsze kroki.',
          ctaLabel: 'Zgłoś nieruchomość',
          onTap: () => context.go(AppRouter.chceSprzedac),
        ),
        const SizedBox(height: AppSpacing.lg),
        _HomeTile(
          icon: Icons.calculate_rounded,
          title: 'Kalkulator ROI',
          subtitle: 'Oblicz stopę zwrotu i czas zwrotu – za gotówkę lub z lewarem. Na końcu zobacz oferty o podobnych parametrach.',
          ctaLabel: 'Oblicz ROI',
          onTap: () => context.go(AppRouter.kalkulatorRoi),
        ),
      ],
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    // IntrinsicHeight ensures the Row gets a bounded height when inside
    // SingleChildScrollView (which provides unbounded vertical constraints).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _HomeTile(
            icon: Icons.trending_up_rounded,
            title: 'Jestem Inwestorem',
            subtitle: 'Baza ofert (teasery). Logowanie (LinkedIn/NIP) → NDA → dostęp do pełnych danych i VDR.',
            ctaLabel: 'Zobacz oferty',
            onTap: () => context.go(AppRouter.oferty),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _HomeTile(
            icon: Icons.real_estate_agent_rounded,
            title: 'Chcę sprzedać nieruchomość / grunt',
            subtitle: 'Zgłoś swoją nieruchomość – skontaktujemy się i zaproponujemy dalsze kroki.',
            ctaLabel: 'Zgłoś nieruchomość',
            onTap: () => context.go(AppRouter.chceSprzedac),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _HomeTile(
            icon: Icons.calculate_rounded,
            title: 'Kalkulator ROI',
            subtitle: 'Oblicz stopę zwrotu i czas zwrotu – za gotówkę lub z lewarem. Na końcu zobacz oferty o podobnych parametrach.',
            ctaLabel: 'Oblicz ROI',
            onTap: () => context.go(AppRouter.kalkulatorRoi),
          ),
        ),
      ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: isMobile ? 36 : 44,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
              Row(
                children: [
                  Text(
                    ctaLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.arrowForward,
                    size: AppSpacing.iconSm,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
