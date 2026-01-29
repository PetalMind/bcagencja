import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/custom_button.dart';

/// Strona "O nas" – prezentacja agencji i zespołu.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AboutHero(isMobile: isMobile),
            _SectionIntro(isMobile: isMobile),
            _SectionMission(isMobile: isMobile),
            _SectionValues(isMobile: isMobile),
            _SectionStats(isMobile: isMobile),
            _SectionCta(context, isMobile),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _SectionCta(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      color: AppColors.grey50,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Chcesz porozmawiać o inwestycji?',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Skontaktuj się z nami – pomożemy dobrać ofertę i odpowiedzieć na pytania.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                label: 'Kontakt',
                onPressed: () => context.go(AppRouter.contact),
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  final bool isMobile;

  const _AboutHero({required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'O nas',
                style: (isMobile
                        ? AppTextStyles.headlineLarge
                        : AppTextStyles.displaySmall)
                    .copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'BC Agencja – nieruchomości komercyjne i inwestycyjne',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                  fontSize: isMobile ? 14 : 16,
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

class _SectionIntro extends StatelessWidget {
  final bool isMobile;

  const _SectionIntro({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidthNarrow),
          child: Column(
            children: [
              Text(
                'Kim jesteśmy',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Jesteśmy agencją specjalizującą się w nieruchomościach komercyjnych '
                'i inwestycyjnych. Pomagamy firmom, inwestorom i developerom w znalezieniu '
                'biur, magazynów, hal, działek oraz obiektów pod hotele i handel. '
                'Działamy w całej Polsce i łączymy oferty z wiarygodnymi sprzedawcami.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
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

class _SectionMission extends StatelessWidget {
  final bool isMobile;

  const _SectionMission({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      color: AppColors.grey50,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Nasza misja',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ułatwiać transakcje na rynku nieruchomości komercyjnych poprzez '
                'przejrzyste oferty, rzetelną informację i wsparcie na każdym etapie – '
                'od wyszukania obiektu po finalizację umowy.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
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

class _SectionValues extends StatelessWidget {
  final bool isMobile;

  const _SectionValues({required this.isMobile});

  static const List<Map<String, dynamic>> _values = [
    {'icon': AppIcons.check, 'title': 'Rzetelność', 'desc': 'Sprawdzone oferty i uczciwe opisy.'},
    {'icon': AppIcons.security, 'title': 'Bezpieczeństwo', 'desc': 'Wsparcie prawno-formalne i weryfikacja stron.'},
    {'icon': AppIcons.location, 'title': 'Zasięg', 'desc': 'Oferty z całej Polski w jednym miejscu.'},
    {'icon': AppIcons.message, 'title': 'Kontakt', 'desc': 'Szybka odpowiedź i indywidualne podejście.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Nasze wartości',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = isMobile ? 1 : 2;
                  final children = _values.map((v) => _ValueCard(
                    icon: v['icon'] as IconData,
                    title: v['title'] as String,
                    description: v['desc'] as String,
                    isMobile: isMobile,
                  )).toList();
                  if (crossAxisCount == 1) {
                    return Column(
                      children: children
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: c,
                              ))
                          .toList(),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: isMobile ? 1.2 : 2.2,
                    children: children,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isMobile;

  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: AppSpacing.iconLg),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionStats extends StatelessWidget {
  final bool isMobile;

  const _SectionStats({required this.isMobile});

  static const List<Map<String, String>> _stats = [
    {'value': '15 000+', 'label': 'Aktywnych ofert'},
    {'value': '50 000+', 'label': 'Zadowolonych klientów'},
    {'value': '200+', 'label': 'Zweryfikowanych agentów'},
    {'value': '100+', 'label': 'Miast w Polsce'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Zaufało nam już tysiące klientów',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              isMobile
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _stats.length,
                      itemBuilder: (context, index) {
                        final s = _stats[index];
                        return _StatItem(
                          value: s['value']!,
                          label: s['label']!,
                        );
                      },
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _stats
                          .map((s) => _StatItem(
                                value: s['value']!,
                                label: s['label']!,
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
