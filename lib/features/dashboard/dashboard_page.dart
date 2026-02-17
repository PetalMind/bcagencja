import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';
import '../../core/state/providers/dashboard_providers.dart';
import 'dashboard_strings.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static List<_DashboardSection> _sectionsForRole(
    UserRoleLevel role,
    int favoritesCount,
    int listingsCount,
    int mySubmissionsCount,
    int alertsCount,
    int messagesCount,
  ) {
    final hasPartner = RolePermissions.hasPartnerDashboard(role);
    final isAdmin = RolePermissions.hasAdminDashboard(role);
    return [
      if (hasPartner)
        _DashboardSection(
          title: DashboardStrings.sectionMyListings,
          value: '$listingsCount',
          icon: AppIcons.office,
          route: AppRouter.dashboardListings,
        )
      else
        _DashboardSection(
          title: DashboardStrings.sectionFavorites,
          value: '$favoritesCount',
          icon: AppIcons.favorites,
          route: AppRouter.dashboardFavorites,
        ),
      if (hasPartner)
        _DashboardSection(
          title: DashboardStrings.sectionFavoritesAlt,
          value: '$favoritesCount',
          icon: AppIcons.favorites,
          route: AppRouter.dashboardFavorites,
        ),
      _DashboardSection(
        title: DashboardStrings.sectionMySubmissions,
        value: mySubmissionsCount > 0 ? '$mySubmissionsCount' : '',
        icon: Icons.real_estate_agent_outlined,
        route: AppRouter.dashboardMySubmissions,
      ),
      _DashboardSection(
        title: DashboardStrings.sectionAlerts,
        value: '$alertsCount',
        icon: AppIcons.notifications,
        route: AppRouter.dashboardAlerts,
      ),
      _DashboardSection(
        title: DashboardStrings.sectionMessages,
        value: '$messagesCount',
        icon: AppIcons.message,
        route: AppRouter.dashboardMessages,
      ),
      if (hasPartner)
        const _DashboardSection(
          title: DashboardStrings.sectionStatistics,
          value: DashboardStrings.valueDash,
          icon: AppIcons.statistics,
          route: AppRouter.dashboardStatistics,
        ),
      const _DashboardSection(
        title: DashboardStrings.sectionSettings,
        value: '',
        icon: AppIcons.settings,
        route: AppRouter.dashboardSettings,
      ),
      if (isAdmin) ...[
        const _DashboardSection(
          title: DashboardStrings.sectionAdminOverview,
          value: '',
          icon: Icons.dashboard_outlined,
          route: AppRouter.dashboardAdminOverview,
        ),
        const _DashboardSection(
          title: DashboardStrings.sectionAdminSubmissions,
          value: '',
          icon: Icons.real_estate_agent_outlined,
          route: AppRouter.dashboardAdminSubmissions,
        ),
        const _DashboardSection(
          title: DashboardStrings.sectionAdminUsers,
          value: '',
          icon: Icons.admin_panel_settings,
          route: AppRouter.dashboardAdminUsers,
        ),
        const _DashboardSection(
          title: DashboardStrings.sectionAdminLogs,
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
    final listingsCount = ref.watch(partnerListingsCountProvider);
    final mySubmissionsCount = ref.watch(mySubmissionsCountProvider).valueOrNull ?? 0;
    final alertsCount = ref.watch(dashboardAlertsCountProvider);
    final messagesCount = ref.watch(dashboardMessagesCountProvider);
    final sections = _sectionsForRole(
      roleLevel,
      favoritesCount,
      listingsCount,
      mySubmissionsCount,
      alertsCount,
      messagesCount,
    );
    final newListingsItems = ref.watch(newListingsPreviewProvider);
    final messagesItems = ref.watch(messagesPreviewProvider);
    final recentlyViewedItems =
        ref.watch(recentlyViewedPreviewProvider).valueOrNull ?? [];
    final userCriteriaItems = ref.watch(userCriteriaPreviewProvider);

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
      body: SafeArea(
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
                  newListingsItems: newListingsItems,
                  newListingsCount: newListingsItems.length,
                  messagesItems: messagesItems,
                  messagesCount: messagesItems.length,
                  recentlyViewedItems: recentlyViewedItems,
                  userCriteriaItems: userCriteriaItems,
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
    required this.newListingsItems,
    required this.newListingsCount,
    required this.messagesItems,
    required this.messagesCount,
    required this.recentlyViewedItems,
    required this.userCriteriaItems,
  });

  final bool isMobile;
  final bool isTablet;
  final bool showVerifyCta;
  final bool showVdrCta;
  final bool showNdaBanner;
  final int favoritesCount;
  final List<String> newListingsItems;
  final int newListingsCount;
  final List<String> messagesItems;
  final int messagesCount;
  final List<RecentlyViewedItem> recentlyViewedItems;
  final List<String> userCriteriaItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = !isMobile &&
            constraints.maxWidth > AppSpacing.dashboardTwoColumnMinWidth;
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
                      child: _InvestorQuickActions(
                        isMobile: isMobile,
                        favoritesCount: favoritesCount,
                        newListingsItems: newListingsItems,
                        newListingsCount: newListingsCount,
                        messagesItems: messagesItems,
                        messagesCount: messagesCount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    SizedBox(
                      width: AppSpacing.dashboardSidebarWidth,
                      child: _InvestorSidebar(
                        showVdrCta: showVdrCta,
                        recentlyViewedItems: recentlyViewedItems,
                        userCriteriaItems: userCriteriaItems,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InvestorQuickActions(
                    isMobile: isMobile,
                    favoritesCount: favoritesCount,
                    newListingsItems: newListingsItems,
                    newListingsCount: newListingsCount,
                    messagesItems: messagesItems,
                    messagesCount: messagesCount,
                  ),
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
    required this.newListingsItems,
    required this.newListingsCount,
    required this.messagesItems,
    required this.messagesCount,
  });

  final bool isMobile;
  final int favoritesCount;
  final List<String> newListingsItems;
  final int newListingsCount;
  final List<String> messagesItems;
  final int messagesCount;

  @override
  Widget build(BuildContext context) {
    final favoritesItems = favoritesCount > 0
        ? ['$favoritesCount ${DashboardStrings.favoritesCountLabel}']
        : [DashboardStrings.emptyFavorites];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickActionCard(
          title: DashboardStrings.cardNewListings,
          count: newListingsCount,
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.ctaHighlight,
          items: newListingsItems.isEmpty
              ? [DashboardStrings.emptyNewListings(AppConfig.newListingsMaxAgeDays)]
              : newListingsItems,
          actionLabel: DashboardStrings.actionSeeAll,
          route: AppRouter.oferty,
          isMobile: isMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickActionCard(
          title: DashboardStrings.cardSavedListings,
          count: favoritesCount,
          icon: AppIcons.favorites,
          iconColor: AppColors.accent,
          items: favoritesItems,
          actionLabel: DashboardStrings.actionManage,
          route: AppRouter.dashboardFavorites,
          isMobile: isMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickActionCard(
          title: DashboardStrings.cardMessages,
          count: messagesCount,
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: AppColors.info,
          items: messagesItems,
          actionLabel: DashboardStrings.actionSeeMessages,
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
                  Icon(icon, size: AppSpacing.iconMd, color: iconColor),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
  const _InvestorSidebar({
    required this.showVdrCta,
    required this.recentlyViewedItems,
    required this.userCriteriaItems,
  });

  final bool showVdrCta;
  final List<RecentlyViewedItem> recentlyViewedItems;
  final List<String> userCriteriaItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarCard(
          title: DashboardStrings.sidebarRecentlyViewed,
          items: recentlyViewedItems.map((e) => e.displayLabel).toList(),
          itemRoutes: recentlyViewedItems
              .map((e) => '/property/${e.listingId}')
              .toList(),
          actionLabel: DashboardStrings.sidebarBackToListings,
          route: AppRouter.oferty,
        ),
        const SizedBox(height: AppSpacing.md),
        _SidebarCard(
          title: DashboardStrings.sidebarYourCriteria,
          items: userCriteriaItems,
          actionLabel: DashboardStrings.sidebarEditPreferences,
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
    this.itemRoutes,
  });

  final String title;
  final List<String> items;
  final String actionLabel;
  final String route;
  /// Opcjonalne linki per pozycja (ta sama długość co [items]). Gdy podane, wiersz jest klikalny.
  final List<String>? itemRoutes;

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
              ...List.generate(items.length, (i) {
                final label = items[i];
                final itemRoute =
                    itemRoutes != null && i < itemRoutes!.length
                        ? itemRoutes![i]
                        : null;
                final text = Text(
                  '• $label',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: itemRoute != null && itemRoute.isNotEmpty
                      ? InkWell(
                          onTap: () => context.go(itemRoute),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          child: text,
                        )
                      : text,
                );
              }),
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
                  Icon(
                    Icons.lock_open_rounded,
                    color: AppColors.ctaHighlight,
                    size: AppSpacing.iconMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DashboardStrings.vdrCtaTitle,
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
                DashboardStrings.vdrCtaDescription,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                DashboardStrings.vdrCtaAction,
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
              onTap: () => context.push(AppRouter.chceSprzedac),
              isMobile: isMobile,
            ),
          ),
        _SectionLabel(
          label: hasPartner
              ? DashboardStrings.sectionLabelAgent
              : DashboardStrings.sectionLabelInvestor,
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
            isMobile
                ? DashboardStrings.titleShort
                : DashboardStrings.titleLong,
            style: isMobile
                ? AppTextStyles.headlineMedium
                : AppTextStyles.headlineLarge,
          ),
          if (isMobile) const SizedBox(height: AppSpacing.xs),
          Text(
            DashboardStrings.subtitle,
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
      label: DashboardStrings.searchSemanticLabel,
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
              vertical: isMobile ? AppSpacing.md : AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.search,
                  size: isMobile ? AppSpacing.iconMd : AppSpacing.iconSm,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                Expanded(
                  child: Text(
                    DashboardStrings.searchPlaceholder,
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
        ? DashboardStrings.verifyCtaNda
        : DashboardStrings.verifyCtaIdentity;

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
              minHeight: isMobile
                  ? AppSpacing.minTouchTarget * 1.25
                  : AppSpacing.minTouchTarget,
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
                    size: isMobile ? AppSpacing.iconMd : AppSpacing.iconSm,
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
      label: DashboardStrings.addListingSemantic,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? AppSpacing.radiusLg : AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile
                  ? AppSpacing.minTouchTarget * 1.25
                  : AppSpacing.minTouchTarget,
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
                    size: isMobile ? AppSpacing.iconMd : AppSpacing.iconSm,
                    color: AppColors.white,
                  ),
                  SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                  Text(
                    DashboardStrings.addListing,
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
              minHeight: AppSpacing.minTouchTarget * 1.2,
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
      label: '${section.title}, ${section.value.isNotEmpty && section.value != DashboardStrings.valueDash ? section.value : ''}',
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
    final showValue = section.value.isNotEmpty && section.value != DashboardStrings.valueDash;
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: Center(
            child: Container(
              width: AppSpacing.dashboardIconContainerSize,
              height: AppSpacing.dashboardIconContainerSize,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                section.icon,
                size: AppSpacing.dashboardIconSizeCard,
                color: AppColors.accent,
              ),
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
                const SizedBox(height: AppSpacing.xs),
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
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: Center(
            child: Icon(
              AppIcons.chevronRight,
              size: AppSpacing.iconSm,
              color: AppColors.grey400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final showValue = section.value.isNotEmpty && section.value != DashboardStrings.valueDash;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            section.icon,
            size: AppSpacing.iconXl,
            color: AppColors.accent,
          ),
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
