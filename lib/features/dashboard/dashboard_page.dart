import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/sidebar.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';

/// Minimalny rozmiar obszaru dotyku (Material / Apple HIG)
const double _kMinTouchTarget = 48.0;

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static List<_DashboardSection> _sectionsForRole(UserRoleLevel role, int favoritesCount) {
    final hasPartner = RolePermissions.hasPartnerDashboard(role);
    final isAdmin = RolePermissions.hasAdminDashboard(role);
    return [
      if (hasPartner)
        const _DashboardSection(
          title: 'Moje ogłoszenia',
          value: '5',
          icon: AppIcons.office,
          route: AppRouter.dashboardListings,
        )
      else
        _DashboardSection(
          title: 'Zapisane oferty',
          value: '$favoritesCount',
          icon: AppIcons.favorites,
          route: AppRouter.dashboardFavorites,
        ),
      if (hasPartner)
        _DashboardSection(
          title: 'Ulubione',
          value: '$favoritesCount',
          icon: AppIcons.favorites,
          route: AppRouter.dashboardFavorites,
        ),
      const _DashboardSection(
        title: 'Zapisane wyszukiwania',
        value: '2',
        icon: AppIcons.notifications,
        route: AppRouter.dashboardAlerts,
      ),
      const _DashboardSection(
        title: 'Wiadomości',
        value: '2',
        icon: AppIcons.message,
        route: AppRouter.dashboardMessages,
      ),
      if (hasPartner)
        const _DashboardSection(
          title: 'Statystyki',
          value: '—',
          icon: AppIcons.statistics,
          route: AppRouter.dashboardStatistics,
        ),
      const _DashboardSection(
        title: 'Ustawienia',
        value: '',
        icon: AppIcons.settings,
        route: AppRouter.dashboardSettings,
      ),
      if (isAdmin) ...[
        const _DashboardSection(
          title: 'Oczekujące (Chcę sprzedać)',
          value: '',
          icon: Icons.real_estate_agent_outlined,
          route: AppRouter.dashboardAdminSubmissions,
        ),
        const _DashboardSection(
          title: 'Użytkownicy',
          value: '',
          icon: Icons.admin_panel_settings,
          route: AppRouter.dashboardAdminUsers,
        ),
        const _DashboardSection(
          title: 'Logi systemowe',
          value: '',
          icon: Icons.history,
          route: AppRouter.dashboardAdminLogs,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final padding = media.padding;
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint && screenWidth < AppSpacing.tabletBreakpoint;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final favoritesCount = ref.watch(favoritesProvider).length;
    final showVerifyCta = user != null && !user.hasIdentityVerifiedAccess;
    final showVdrCta = user != null &&
        (user.effectiveRoleLevel == UserRoleLevel.investorVerified) &&
        !RolePermissions.canAccessVdr(user.effectiveRoleLevel);
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
    final hasPartner = RolePermissions.hasPartnerDashboard(roleLevel);
    final isInvestor = RolePermissions.hasInvestorDashboard(roleLevel);
    final sections = _sectionsForRole(roleLevel, favoritesCount);

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
                child: isInvestor && !hasPartner
                    ? _InvestorDashboardContent(
                        isMobile: isMobile,
                        isTablet: isTablet,
                        showVerifyCta: showVerifyCta,
                        showVdrCta: showVdrCta,
                        showNdaBanner: user?.shouldShowNdaBanner ?? false,
                        favoritesCount: favoritesCount,
                      )
                    : _DefaultDashboardContent(
                        isMobile: isMobile,
                        isTablet: isTablet,
                        hasPartner: hasPartner,
                        showVerifyCta: showVerifyCta,
                        showNdaBanner: user?.shouldShowNdaBanner ?? false,
                        sections: sections,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestorDashboardContent extends StatelessWidget {
  const _InvestorDashboardContent({
    required this.isMobile,
    required this.isTablet,
    required this.showVerifyCta,
    required this.showVdrCta,
    required this.showNdaBanner,
    required this.favoritesCount,
  });

  final bool isMobile;
  final bool isTablet;
  final bool showVerifyCta;
  final bool showVdrCta;
  final bool showNdaBanner;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = !isMobile && constraints.maxWidth > 800;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(isMobile: isMobile),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
            if (showVerifyCta)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _VerifyAccountCta(
                  isMobile: isMobile,
                  showNdaBanner: showNdaBanner,
                ),
              ),
            _QuickSearchBar(isMobile: isMobile),
            const SizedBox(height: AppSpacing.lg),
            if (useTwoColumns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _InvestorQuickActions(isMobile: isMobile, favoritesCount: favoritesCount),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    SizedBox(
                      width: 320,
                      child: _InvestorSidebar(showVdrCta: showVdrCta),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InvestorQuickActions(isMobile: isMobile, favoritesCount: favoritesCount),
                  if (showVdrCta) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _VdrCtaCard(isMobile: isMobile),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _InvestorQuickActions extends StatelessWidget {
  const _InvestorQuickActions({
    required this.isMobile,
    required this.favoritesCount,
  });

  final bool isMobile;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickActionCard(
          title: 'Nowe oferty',
          count: 3,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.ctaHighlight,
          items: const [
            'Biedronka Poznań – 8.2% ROI',
            'Grunt Wrocław – MPZP zatw.',
            'Lidl Gdańsk – Long lease',
          ],
          actionLabel: 'Zobacz wszystkie',
          route: AppRouter.oferty,
          isMobile: isMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickActionCard(
          title: 'Zapisane oferty',
          count: favoritesCount,
          icon: AppIcons.favorites,
          iconColor: AppColors.accent,
          items: [
            if (favoritesCount > 0) '$favoritesCount ofert w ulubionych',
            if (favoritesCount == 0) 'Brak zapisanych ofert',
          ],
          actionLabel: 'Zarządzaj',
          route: AppRouter.dashboardFavorites,
          isMobile: isMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickActionCard(
          title: 'Wiadomości',
          count: 2,
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: AppColors.info,
          items: const [
            'Dyrektor ds. Mazowsza odpowiedział na zapytanie',
            'Nowa odpowiedź w ofercie "Lidl Kraków"',
          ],
          actionLabel: 'Zobacz wiadomości',
          route: AppRouter.dashboardMessages,
          isMobile: isMobile,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.actionLabel,
    required this.route,
    required this.isMobile,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final List<String> items;
  final String actionLabel;
  final String route;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...items.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $s',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$actionLabel →',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorSidebar extends StatelessWidget {
  const _InvestorSidebar({required this.showVdrCta});

  final bool showVdrCta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarCard(
          title: 'Ostatnio oglądane',
          items: const [
            'Lokal Warszawa Centrum – 7.8% ROI',
            'Lidl Kraków',
            'Grunt Łódź',
          ],
          actionLabel: 'Wróć do ofert',
          route: AppRouter.oferty,
        ),
        const SizedBox(height: AppSpacing.md),
        _SidebarCard(
          title: 'Twoje kryteria',
          items: const [
            'ROI min: 7%',
            'Budżet: 2–5M PLN',
            'Region: Mazowieckie',
          ],
          actionLabel: 'Edytuj preferencje',
          route: AppRouter.dashboardSettings,
        ),
        if (showVdrCta) ...[
          const SizedBox(height: AppSpacing.md),
          _VdrCtaCard(isMobile: false),
        ],
      ],
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({
    required this.title,
    required this.items,
    required this.actionLabel,
    required this.route,
  });

  final String title;
  final List<String> items;
  final String actionLabel;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $s',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$actionLabel →',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VdrCtaCard extends StatelessWidget {
  const _VdrCtaCard({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ctaHighlight.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () => context.go(AppRouter.weryfikacja),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: AppColors.ctaHighlight, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ODBLOKUJ VDR',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.ctaHighlight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Uzyskaj dostęp do pełnej dokumentacji, operatów szacunkowych i umów najmu',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Wyślij Proof of Funds →',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.ctaHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultDashboardContent extends StatelessWidget {
  const _DefaultDashboardContent({
    required this.isMobile,
    required this.isTablet,
    required this.hasPartner,
    required this.showVerifyCta,
    required this.showNdaBanner,
    required this.sections,
  });

  final bool isMobile;
  final bool isTablet;
  final bool hasPartner;
  final bool showVerifyCta;
  final bool showNdaBanner;
  final List<_DashboardSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderSection(isMobile: isMobile),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        if (showVerifyCta)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _VerifyAccountCta(isMobile: isMobile, showNdaBanner: showNdaBanner),
          ),
        _QuickSearchBar(isMobile: isMobile),
        const SizedBox(height: AppSpacing.lg),
        if (hasPartner)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _QuickActionCta(
              onTap: () => context.push(AppRouter.addListing),
              isMobile: isMobile,
            ),
          ),
        _SectionLabel(
          label: hasPartner ? 'Panel Agenta' : 'Panel Inwestora',
          isMobile: isMobile,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionsGrid(
          sections: sections,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
      ],
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
                    'Szukaj według lokalizacji, typu, najemcy...',
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

class _VerifyAccountCta extends StatelessWidget {
  const _VerifyAccountCta({
    required this.isMobile,
    this.showNdaBanner = false,
  });

  final bool isMobile;
  /// INVESTOR_BASIC: banner „Zaakceptuj NDA”. Inni: zweryfikuj konto.
  final bool showNdaBanner;

  @override
  Widget build(BuildContext context) {
    final label = showNdaBanner
        ? 'Zaakceptuj NDA, aby odblokować pełne oferty'
        : 'Zweryfikuj konto – zobacz pełne oferty (lokalizacja, galeria)';

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => context.go(AppRouter.weryfikacja),
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
                    Icons.verified_user_outlined,
                    size: isMobile ? 24 : 22,
                    color: AppColors.info,
                  ),
                  SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.info,
                      ),
                      textAlign: TextAlign.center,
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
        childAspectRatio: isTablet ? 1.15 : 1.25,
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
