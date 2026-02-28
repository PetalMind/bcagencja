import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';
import '../../core/state/providers/dashboard_providers.dart';
import 'dashboard_strings.dart';

/// Opakowanie widgetu dla tutorial coach mark – wymagane [GlobalKey]<[State]<[StatefulWidget]>.
class _CoachMarkTarget extends StatefulWidget {
  const _CoachMarkTarget({super.key, required this.child});
  final Widget child;

  @override
  State<_CoachMarkTarget> createState() => _CoachMarkTargetState();
}

class _CoachMarkTargetState extends State<_CoachMarkTarget> {
  @override
  Widget build(BuildContext context) => widget.child;
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ── Wspólne ───────────────────────────────────────────────────
  final GlobalKey<_CoachMarkTargetState> _headerKey =
      GlobalKey<_CoachMarkTargetState>();
  final GlobalKey<_CoachMarkTargetState> _searchKey =
      GlobalKey<_CoachMarkTargetState>();
  final GlobalKey<_CoachMarkTargetState> _sectionsKey =
      GlobalKey<_CoachMarkTargetState>();

  // ── Level 1 (investorBasic) ───────────────────────────────────
  final GlobalKey<_CoachMarkTargetState> _verifyBannerKey =
      GlobalKey<_CoachMarkTargetState>();

  // ── Level 2 (investorVerified / VIP) ─────────────────────────
  final GlobalKey<_CoachMarkTargetState> _ctaStripKey =
      GlobalKey<_CoachMarkTargetState>();

  // ── Level 4+ (agent / director) ──────────────────────────────
  final GlobalKey<_CoachMarkTargetState> _addListingKey =
      GlobalKey<_CoachMarkTargetState>();

  bool _tutorialScheduled = false;

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

  void _maybeShowTutorial(BuildContext context) {
    if (_tutorialScheduled || !mounted) return;
    final seen = ref.read(dashboardTutorialSeenProvider).value ?? true;
    if (seen) return;
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider).asData?.value;
      final role = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
      _showTutorialForRole(context, role);
    });
  }

  // ────────────────────────────────────────────────────────────
  // Pomocnicza metoda budująca jeden krok tutorialu.
  // ────────────────────────────────────────────────────────────
  TargetFocus? _step(
    String id,
    GlobalKey<_CoachMarkTargetState> key,
    String title,
    String desc,
    ContentAlign align,
  ) {
    if (key.currentContext == null) return null;
    return TargetFocus(
      identify: id,
      keyTarget: key as GlobalKey<State<StatefulWidget>>,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      paddingFocus: 8,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: align,
          child: _TutorialContent(title: title, desc: desc),
        ),
      ],
    );
  }

  // ── Ścieżka dla Level 1 (investorBasic) ──────────────────────
  List<TargetFocus> _targetsLevel1() => [
        _step('header', _headerKey,
            DashboardStrings.tutorialL1WelcomeTitle,
            DashboardStrings.tutorialL1WelcomeDesc,
            ContentAlign.bottom),
        _step('verify', _verifyBannerKey,
            DashboardStrings.tutorialL1VerifyTitle,
            DashboardStrings.tutorialL1VerifyDesc,
            ContentAlign.bottom),
        _step('search', _searchKey,
            DashboardStrings.tutorialL1SearchTitle,
            DashboardStrings.tutorialL1SearchDesc,
            ContentAlign.bottom),
        _step('cards', _sectionsKey,
            DashboardStrings.tutorialL1CardsTitle,
            DashboardStrings.tutorialL1CardsDesc,
            ContentAlign.top),
      ].whereType<TargetFocus>().toList();

  // ── Ścieżka dla Level 2/3 (investorVerified / VIP) ───────────
  List<TargetFocus> _targetsLevel2() => [
        _step('header', _headerKey,
            DashboardStrings.tutorialL2WelcomeTitle,
            DashboardStrings.tutorialL2WelcomeDesc,
            ContentAlign.bottom),
        _step('cta', _ctaStripKey,
            DashboardStrings.tutorialL2CtaTitle,
            DashboardStrings.tutorialL2CtaDesc,
            ContentAlign.bottom),
        _step('search', _searchKey,
            DashboardStrings.tutorialL2SearchTitle,
            DashboardStrings.tutorialL2SearchDesc,
            ContentAlign.bottom),
        _step('cards', _sectionsKey,
            DashboardStrings.tutorialL2NewListingsTitle,
            DashboardStrings.tutorialL2NewListingsDesc,
            ContentAlign.top),
      ].whereType<TargetFocus>().toList();

  // ── Ścieżka dla agenta / dyrektora ───────────────────────────
  List<TargetFocus> _targetsAgent() => [
        _step('header', _headerKey,
            DashboardStrings.tutorialAgentWelcomeTitle,
            DashboardStrings.tutorialAgentWelcomeDesc,
            ContentAlign.bottom),
        _step('addListing', _addListingKey,
            DashboardStrings.tutorialAgentAddListingTitle,
            DashboardStrings.tutorialAgentAddListingDesc,
            ContentAlign.bottom),
        _step('search', _searchKey,
            DashboardStrings.tutorialAgentSearchTitle,
            DashboardStrings.tutorialAgentSearchDesc,
            ContentAlign.bottom),
        _step('sections', _sectionsKey,
            DashboardStrings.tutorialAgentMyListingsTitle,
            DashboardStrings.tutorialAgentMyListingsDesc,
            ContentAlign.top),
      ].whereType<TargetFocus>().toList();

  void _showTutorialForRole(BuildContext context, UserRoleLevel role) {
    if (!mounted) return;

    final List<TargetFocus> targets;
    if (RolePermissions.hasPartnerDashboard(role)) {
      targets = _targetsAgent();
    } else if (role == UserRoleLevel.investorBasic) {
      targets = _targetsLevel1();
    } else if (RolePermissions.hasInvestorDashboard(role)) {
      targets = _targetsLevel2();
    } else {
      // Admin/guest – pomijamy tutorial
      ref.read(dashboardTutorialSeenProvider.notifier).markSeen();
      return;
    }

    if (targets.isEmpty) return;

    final notifier = ref.read(dashboardTutorialSeenProvider.notifier);
    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryDark,
      paddingFocus: 10,
      opacityShadow: 0.82,
      onFinish: notifier.markSeen,
      onSkip: () {
        notifier.markSeen();
        return true;
      },
      textSkip: DashboardStrings.tutorialSkip,
      alignSkip: Alignment.topRight,
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final padding = media.padding;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint && screenWidth < AppSpacing.tabletBreakpoint;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final user = ref.watch(currentUserProvider).asData?.value;
    final favoritesCount = ref.watch(favoritesProvider).length;
    final showVerifyCta = user != null && !user.hasIdentityVerifiedAccess;
    final showVdrCta = user != null &&
        (user.effectiveRoleLevel == UserRoleLevel.investorVerified) &&
        !RolePermissions.canAccessVdr(user.effectiveRoleLevel);
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
    final hasPartner = RolePermissions.hasPartnerDashboard(roleLevel);
    final isInvestor = RolePermissions.hasInvestorDashboard(roleLevel);
    final listingsCount = ref.watch(partnerListingsCountProvider);
    final mySubmissionsCount = ref.watch(mySubmissionsCountProvider).asData?.value ?? 0;
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
        ref.watch(recentlyViewedPreviewProvider).asData?.value ?? [];
    final userCriteriaItems = ref.watch(userCriteriaPreviewProvider);

    ref.listen(dashboardTutorialSeenProvider, (prev, next) {
      next.whenData((seen) {
        if (!seen && !_tutorialScheduled) _maybeShowTutorial(context);
      });
    });
    final tutorialSeen = ref.watch(dashboardTutorialSeenProvider).value ?? true;
    if (!tutorialSeen && !_tutorialScheduled) _maybeShowTutorial(context);

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
                  user: user,
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
                  headerKey: _headerKey,
                  verifyBannerKey: _verifyBannerKey,
                  ctaStripKey: _ctaStripKey,
                  searchKey: _searchKey,
                  sectionsKey: _sectionsKey,
                )
              : _DefaultDashboardContent(
                  user: user,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  hasPartner: hasPartner,
                  showVerifyCta: showVerifyCta,
                  showNdaBanner: user?.shouldShowNdaBanner ?? false,
                  sections: sections,
                  headerKey: _headerKey,
                  addListingKey: _addListingKey,
                  searchKey: _searchKey,
                  sectionsKey: _sectionsKey,
                ),
        ),
      ),
    );
  }
}

class _InvestorDashboardContent extends StatelessWidget {
  const _InvestorDashboardContent({
    required this.user,
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
    this.headerKey,
    this.verifyBannerKey,
    this.ctaStripKey,
    this.searchKey,
    this.sectionsKey,
  });

  final AppUser? user;
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
  final GlobalKey<_CoachMarkTargetState>? headerKey;
  final GlobalKey<_CoachMarkTargetState>? verifyBannerKey;
  final GlobalKey<_CoachMarkTargetState>? ctaStripKey;
  final GlobalKey<_CoachMarkTargetState>? searchKey;
  final GlobalKey<_CoachMarkTargetState>? sectionsKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = !isMobile &&
            constraints.maxWidth > AppSpacing.dashboardTwoColumnMinWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerKey != null)
              _CoachMarkTarget(
                key: headerKey,
                child: _HeaderSection(isMobile: isMobile, user: user, isInvestorVerified: !showVerifyCta),
              )
            else
              _HeaderSection(isMobile: isMobile, user: user, isInvestorVerified: !showVerifyCta),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
            if (showVerifyCta)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: verifyBannerKey != null
                    ? _CoachMarkTarget(
                        key: verifyBannerKey,
                        child: _UnverifiedUserBanner(
                          isMobile: isMobile,
                          showNdaBanner: showNdaBanner,
                        ),
                      )
                    : _UnverifiedUserBanner(
                        isMobile: isMobile,
                        showNdaBanner: showNdaBanner,
                      ),
              )
            else if (ctaStripKey != null)
              _CoachMarkTarget(
                key: ctaStripKey,
                child: _QuickCtaStrip(isMobile: isMobile),
              )
            else
              _QuickCtaStrip(isMobile: isMobile),
            if (searchKey != null)
              _CoachMarkTarget(
                key: searchKey,
                child: _QuickSearchBar(isMobile: isMobile),
              )
            else
              _QuickSearchBar(isMobile: isMobile),
            const SizedBox(height: AppSpacing.lg),
            if (useTwoColumns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: sectionsKey != null
                          ? _CoachMarkTarget(
                              key: sectionsKey,
                              child: _InvestorQuickActions(
                                isMobile: isMobile,
                                favoritesCount: favoritesCount,
                                newListingsItems: newListingsItems,
                                newListingsCount: newListingsCount,
                                messagesItems: messagesItems,
                                messagesCount: messagesCount,
                              ),
                            )
                          : _InvestorQuickActions(
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
                  sectionsKey != null
                      ? _CoachMarkTarget(
                          key: sectionsKey,
                          child: _InvestorQuickActions(
                            isMobile: isMobile,
                            favoritesCount: favoritesCount,
                            newListingsItems: newListingsItems,
                            newListingsCount: newListingsCount,
                            messagesItems: messagesItems,
                            messagesCount: messagesCount,
                          ),
                        )
                      : _InvestorQuickActions(
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
          items: userCriteriaItems.isEmpty
              ? [DashboardStrings.ctaSetPreferences]
              : userCriteriaItems,
          actionLabel: userCriteriaItems.isEmpty
              ? 'Ustaw preferencje'
              : DashboardStrings.sidebarEditPreferences,
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
    required this.user,
    required this.isMobile,
    required this.isTablet,
    required this.hasPartner,
    required this.showVerifyCta,
    required this.showNdaBanner,
    required this.sections,
    this.headerKey,
    this.addListingKey,
    this.searchKey,
    this.sectionsKey,
  });

  final AppUser? user;
  final bool isMobile;
  final bool isTablet;
  final bool hasPartner;
  final bool showVerifyCta;
  final bool showNdaBanner;
  final List<_DashboardSection> sections;
  final GlobalKey<_CoachMarkTargetState>? headerKey;
  final GlobalKey<_CoachMarkTargetState>? addListingKey;
  final GlobalKey<_CoachMarkTargetState>? searchKey;
  final GlobalKey<_CoachMarkTargetState>? sectionsKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerKey != null)
          _CoachMarkTarget(
            key: headerKey,
            child: _HeaderSection(isMobile: isMobile, user: user, isInvestorVerified: !showVerifyCta),
          )
        else
          _HeaderSection(isMobile: isMobile, user: user, isInvestorVerified: !showVerifyCta),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        if (showVerifyCta)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _UnverifiedUserBanner(isMobile: isMobile, showNdaBanner: showNdaBanner),
          ),
        if (searchKey != null)
          _CoachMarkTarget(
            key: searchKey,
            child: _QuickSearchBar(isMobile: isMobile),
          )
        else
          _QuickSearchBar(isMobile: isMobile),
        const SizedBox(height: AppSpacing.lg),
        if (hasPartner)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: addListingKey != null
                ? _CoachMarkTarget(
                    key: addListingKey,
                    child: _QuickActionCta(
                      onTap: () => context.push(AppRouter.chceSprzedac),
                      isMobile: isMobile,
                    ),
                  )
                : _QuickActionCta(
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
        sectionsKey != null
            ? _CoachMarkTarget(
                key: sectionsKey,
                child: _SectionsGrid(
                  sections: sections,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              )
            : _SectionsGrid(
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
  const _HeaderSection({
    required this.isMobile,
    this.user,
    this.isInvestorVerified = false,
  });

  final bool isMobile;
  final AppUser? user;
  final bool isInvestorVerified;

  @override
  Widget build(BuildContext context) {
    final firstName = user != null
        ? DashboardStrings.firstName(user!.displayName, user!.email)
        : null;
    final title = firstName != null
        ? DashboardStrings.greetingWithName(firstName)
        : (isMobile ? DashboardStrings.titleShort : DashboardStrings.titleLong);
    final subtitle = user != null && isInvestorVerified
        ? DashboardStrings.subtitleVerified
        : (user != null && !isInvestorVerified
            ? DashboardStrings.subtitleUnverified
            : DashboardStrings.subtitle);

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: isMobile
                      ? AppTextStyles.headlineMedium
                      : AppTextStyles.headlineLarge,
                ),
              ),
              if (user != null && isInvestorVerified) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        DashboardStrings.verifiedBadgeShort,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
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

/// Sekcja dla niezweryfikowanego użytkownika: kroki, korzyści, jeden CTA.
class _UnverifiedUserBanner extends StatelessWidget {
  const _UnverifiedUserBanner({
    required this.isMobile,
    this.showNdaBanner = false,
  });

  final bool isMobile;
  final bool showNdaBanner;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.06),
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          color: AppColors.info.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: AppSpacing.iconLg,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DashboardStrings.unverifiedTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        DashboardStrings.unverifiedSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildStep(DashboardStrings.unverifiedStep1, 1),
            const SizedBox(height: AppSpacing.xs),
            _buildStep(DashboardStrings.unverifiedStep2, 2),
            const SizedBox(height: AppSpacing.xs),
            _buildStep(DashboardStrings.unverifiedStep3, 3),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Po weryfikacji zyskasz:',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBenefit(DashboardStrings.unverifiedBenefit1),
            _buildBenefit(DashboardStrings.unverifiedBenefit2),
            _buildBenefit(DashboardStrings.unverifiedBenefit3),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go(AppRouter.weryfikacja),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text(DashboardStrings.unverifiedCta),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text, int number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pasek szybkich akcji: Przeglądaj oferty, Kalkulator ROI, Chcę sprzedać.
class _QuickCtaStrip extends StatelessWidget {
  const _QuickCtaStrip({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickCtaItem(
        label: DashboardStrings.ctaBrowseListings,
        desc: DashboardStrings.ctaBrowseListingsDesc,
        icon: Icons.search_rounded,
        route: AppRouter.oferty,
        color: AppColors.accent,
      ),
      _QuickCtaItem(
        label: DashboardStrings.ctaRoiCalculator,
        desc: DashboardStrings.ctaRoiCalculatorDesc,
        icon: Icons.bar_chart_rounded,
        route: AppRouter.kalkulatorRoi,
        color: AppColors.ctaHighlight,
      ),
      _QuickCtaItem(
        label: DashboardStrings.ctaWantToSell,
        desc: DashboardStrings.ctaWantToSellDesc,
        icon: Icons.real_estate_agent_rounded,
        route: AppRouter.chceSprzedac,
        color: AppColors.info,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildTile(context, items[i]),
            if (i < items.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _buildTile(context, items[i])),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildTile(BuildContext context, _QuickCtaItem item) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Sprawdź →',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                    ),
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

class _QuickCtaItem {
  const _QuickCtaItem({
    required this.label,
    required this.desc,
    required this.icon,
    required this.route,
    required this.color,
  });
  final String label;
  final String desc;
  final IconData icon;
  final String route;
  final Color color;
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

// ─────────────────────────────────────────────────────────────────────────────
// Widget treści pojedynczego kroku tutorialu.
// ─────────────────────────────────────────────────────────────────────────────
class _TutorialContent extends StatelessWidget {
  const _TutorialContent({required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            desc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
