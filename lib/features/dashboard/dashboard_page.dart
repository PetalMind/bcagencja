import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/sidebar.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';

/// Minimalny rozmiar obszaru dotyku (Material / Apple HIG)
const double _kMinTouchTarget = 48.0;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const List<_DashboardSection> _sections = [
    _DashboardSection(
      title: 'Moje ogłoszenia',
      value: '5',
      icon: AppIcons.office,
      route: AppRouter.dashboardListings,
    ),
    _DashboardSection(
      title: 'Ulubione',
      value: '12',
      icon: AppIcons.favorites,
      route: AppRouter.dashboardFavorites,
    ),
    _DashboardSection(
      title: 'Zapisane wyszukiwania',
      value: '2',
      icon: AppIcons.notifications,
      route: AppRouter.dashboardAlerts,
    ),
    _DashboardSection(
      title: 'Wiadomości',
      value: '3',
      icon: AppIcons.message,
      route: AppRouter.dashboardMessages,
    ),
    _DashboardSection(
      title: 'Statystyki',
      value: '—',
      icon: AppIcons.statistics,
      route: AppRouter.dashboardStatistics,
    ),
    _DashboardSection(
      title: 'Ustawienia',
      value: '',
      icon: AppIcons.settings,
      route: AppRouter.dashboardSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final padding = media.padding;
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint && screenWidth < AppSpacing.tabletBreakpoint;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    final contentPadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)
        : const EdgeInsets.all(AppSpacing.xl);

    final scrollPadding = EdgeInsets.fromLTRB(
      contentPadding.left + padding.left,
      contentPadding.top + padding.top,
      contentPadding.right + padding.right,
      contentPadding.bottom + padding.bottom,
    );

    return Scaffold(
      appBar: const AppBarCustom(),
      drawer: !isDesktop ? const Sidebar() : null,
      body: Row(
        children: [
          if (isDesktop)
            const SizedBox(
              width: 280,
              child: Sidebar(),
            ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              left: false,
              right: false,
              child: SingleChildScrollView(
                padding: scrollPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(isMobile: isMobile),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    _QuickSearchBar(isMobile: isMobile),
                    const SizedBox(height: AppSpacing.lg),

                    _QuickActionCta(
                      onTap: () => context.push(AppRouter.addListing),
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _SectionLabel(label: 'Twoje sekcje', isMobile: isMobile),
                    const SizedBox(height: AppSpacing.sm),

                    _SectionsGrid(
                      sections: _sections,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection {
  const _DashboardSection({
    required this.title,
    required this.value,
    required this.icon,
    required this.route,
  });
  final String title;
  final String value;
  final IconData icon;
  final String route;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMobile ? 'Panel użytkownika' : 'Witaj w panelu użytkownika',
            style: isMobile
                ? AppTextStyles.headlineMedium
                : AppTextStyles.headlineLarge,
          ),
          if (isMobile) const SizedBox(height: AppSpacing.xs),
          Text(
            'Zarządzaj ogłoszeniami, ulubionymi i wiadomościami',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isMobile});

  final String label;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _QuickSearchBar extends StatelessWidget {
  const _QuickSearchBar({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Szybkie wyszukiwanie nieruchomości',
      child: Material(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => context.push(AppRouter.search),
          borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
              vertical: isMobile ? AppSpacing.md + 2 : AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.search,
                  size: isMobile ? 24 : 22,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                Expanded(
                  child: Text(
                    'Szybkie wyszukiwanie nieruchomości...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCta extends StatelessWidget {
  const _QuickActionCta({
    required this.onTap,
    required this.isMobile,
  });

  final VoidCallback onTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dodaj nowe ogłoszenie',
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? _kMinTouchTarget * 1.25 : _kMinTouchTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
                vertical: isMobile ? AppSpacing.md : AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.add,
                    size: isMobile ? 24 : 22,
                    color: AppColors.white,
                  ),
                  SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                  Text(
                    'Dodaj ogłoszenie',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionsGrid extends StatelessWidget {
  const _SectionsGrid({
    required this.sections,
    required this.isMobile,
    required this.isTablet,
  });

  final List<_DashboardSection> sections;
  final bool isMobile;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            _DashboardStatCard(
              section: sections[i],
              isMobile: true,
              minHeight: _kMinTouchTarget * 1.2,
            ),
            if (i < sections.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    final crossAxisCount = isTablet ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: isTablet ? 1.4 : 1.5,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) => _DashboardStatCard(
        section: sections[index],
        isMobile: false,
        minHeight: null,
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.section,
    required this.isMobile,
    this.minHeight,
  });

  final _DashboardSection section;
  final bool isMobile;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${section.title}, ${section.value.isNotEmpty && section.value != '—' ? section.value : ''}',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: isMobile ? 0 : 1,
        shadowColor: AppColors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: () => context.go(section.route),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            constraints: minHeight != null
                ? BoxConstraints(minHeight: minHeight!)
                : null,
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: isMobile
                  ? Border.all(color: AppColors.borderLight, width: 1)
                  : null,
            ),
            child: isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final showValue = section.value.isNotEmpty && section.value != '—';
    return Row(
      children: [
        SizedBox(
          width: _kMinTouchTarget,
          height: _kMinTouchTarget,
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(section.icon, size: 28, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showValue) ...[
                Text(
                  section.value,
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                section.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: showValue ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: _kMinTouchTarget,
          height: _kMinTouchTarget,
          child: Center(
            child: Icon(
              AppIcons.chevronRight,
              size: 20,
              color: AppColors.grey400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final showValue = section.value.isNotEmpty && section.value != '—';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(section.icon, size: 48, color: AppColors.accent),
        const SizedBox(height: AppSpacing.md),
        if (showValue) ...[
          Text(
            section.value,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          section.title,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
