import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/auth/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';

/// Pozycja menu sidebar – może mieć dzieci (rozwijalna sekcja).
class _SidebarItem {
  const _SidebarItem({
    required this.title,
    required this.icon,
    this.route,
    this.children = const [],
    this.badge,
    this.highlighted = false,
    this.queryParams,
  });

  final String title;
  final IconData icon;
  final String? route;
  final List<_SidebarItem> children;
  final String? badge; // np. "3" dla pending items
  final bool highlighted;
  final Map<String, String>? queryParams;

  bool get hasChildren => children.isNotEmpty;
}

class Sidebar extends ConsumerStatefulWidget {
  final String? currentRoute;

  const Sidebar({
    super.key,
    this.currentRoute,
  });

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final Set<String> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _buildHeader(context, roleLevel, user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(context, ref, roleLevel, user),
            ),
          ),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserRoleLevel roleLevel,
    AppUser? user,
  ) {
    final isInvestor = roleLevel == UserRoleLevel.investorBasic ||
        roleLevel == UserRoleLevel.investorVerified ||
        roleLevel == UserRoleLevel.investorVip;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'Użytkownik';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(
                          AppIcons.profile,
                          size: 28,
                          color: AppColors.white,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isInvestor) ...[
                        const SizedBox(height: 2),
                        Text(
                          _verificationBadgeForLevel(roleLevel),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _verificationBadgeForLevel(UserRoleLevel roleLevel) {
    switch (roleLevel) {
      case UserRoleLevel.investorBasic:
        return 'Level 1: Do weryfikacji';
      case UserRoleLevel.investorVerified:
        return 'Level 2: Identity Verified';
      case UserRoleLevel.investorVip:
        return 'Level 3: VDR Access';
      default:
        return '';
    }
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    UserRoleLevel roleLevel,
    AppUser? user,
  ) {
    final items = _menuItemsForRole(roleLevel, user);
    final favoritesCount = ref.watch(favoritesProvider).length;
    final showVdrCta = user != null &&
        (roleLevel == UserRoleLevel.investorBasic || roleLevel == UserRoleLevel.investorVerified) &&
        !RolePermissions.canAccessVdr(roleLevel);

    final widgets = <Widget>[];
    var vdrCtaAdded = false;
    for (final item in items) {
      final isZapisane = item.title == 'Zapisane' || item.title.contains('Ulubione') || item.title.contains('Zapisane');
      final badge = item.badge ?? (isZapisane && favoritesCount > 0 ? '$favoritesCount' : null);
      final itemWithBadge = badge != null ? _SidebarItem(
        title: item.title,
        icon: item.icon,
        route: item.route,
        children: item.children,
        badge: badge,
        highlighted: item.highlighted,
        queryParams: item.queryParams,
      ) : item;
      widgets.add(_buildItemWidget(context, itemWithBadge, null));
      if (showVdrCta && !vdrCtaAdded && item.title == 'Moje dokumenty') {
        widgets.add(_buildVdrCta(context));
        vdrCtaAdded = true;
      }
    }
    if (showVdrCta && !vdrCtaAdded) {
      widgets.add(_buildVdrCta(context));
    }
    return widgets;
  }

  Widget _buildVdrCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Material(
        color: AppColors.ctaHighlight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            context.go(AppRouter.weryfikacja);
            if (context.mounted) Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch, size: 20, color: AppColors.ctaHighlight),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ODBLOKUJ VDR ACCESS',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.ctaHighlight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Zobacz pełną dokumentację, operaty i umowy najmu',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_SidebarItem> _menuItemsForRole(UserRoleLevel roleLevel, AppUser? user) {
    switch (roleLevel) {
      case UserRoleLevel.guest:
        return [];
      case UserRoleLevel.investorBasic:
        return _investorLevel1Items();
      case UserRoleLevel.investorVerified:
        return _investorLevel2Items();
      case UserRoleLevel.investorVip:
        return _investorLevel3Items();
      case UserRoleLevel.agent:
        return _agentItems();
      case UserRoleLevel.director:
        return _directorItems();
      case UserRoleLevel.admin:
        return _adminItems();
    }
  }

  List<_SidebarItem> _investorLevel1Items() {
    return [
      _SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRouter.dashboard),
      _SidebarItem(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
      _SidebarItem(title: 'Zapisane', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
      _SidebarItem(title: 'Kalkulator ROI', icon: Icons.bar_chart_rounded, route: AppRouter.kalkulatorRoi),
      _SidebarItem(title: 'Weryfikacja tożsamości', icon: Icons.verified_user_outlined, route: AppRouter.weryfikacja, highlighted: true),
      _SidebarItem(title: 'Ustawienia', icon: Icons.settings_outlined, route: AppRouter.dashboardSettings),
      _SidebarItem(title: 'Kontakt', icon: AppIcons.phone, route: AppRouter.contact),
    ];
  }

  List<_SidebarItem> _investorLevel2Items() {
    return [
      _SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRouter.dashboard),
      _SidebarItem(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
      _SidebarItem(title: 'Zapisane', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
      _SidebarItem(title: 'Kalkulator ROI', icon: Icons.bar_chart_rounded, route: AppRouter.kalkulatorRoi),
      _SidebarItem(title: 'Moje dokumenty', icon: Icons.folder_outlined, route: AppRouter.dashboardDocuments),
      _SidebarItem(title: 'Ustawienia', icon: Icons.settings_outlined, route: AppRouter.dashboardSettings),
      _SidebarItem(title: 'Kontakt', icon: AppIcons.phone, route: AppRouter.contact),
    ];
  }

  List<_SidebarItem> _investorLevel3Items() {
    return [
      _SidebarItem(
        title: 'Przeglądaj oferty',
        icon: Icons.home_rounded,
        children: [
          _SidebarItem(title: 'Wszystkie nieruchomości', icon: Icons.apartment, route: AppRouter.oferty),
          _SidebarItem(title: 'Grunty', icon: AppIcons.land, route: AppRouter.oferty, queryParams: {'typ': 'land'}),
          _SidebarItem(title: 'Lokale (pustostany)', icon: Icons.store, route: AppRouter.oferty, queryParams: {'typ': 'vacant'}),
          _SidebarItem(title: 'Obiekty z najemcą', icon: Icons.business, route: AppRouter.oferty, queryParams: {'typ': 'tenanted'}),
          _SidebarItem(title: 'Zapisane/Ulubione', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
        ],
      ),
      _SidebarItem(
        title: 'Virtual Data Room',
        icon: Icons.folder_special,
        children: [
          _SidebarItem(title: 'Dostępne VDR', icon: Icons.folder_open, route: AppRouter.dashboardVdr),
          _SidebarItem(title: 'Pobrane dokumenty', icon: Icons.download_done, route: AppRouter.dashboardVdr),
          _SidebarItem(title: 'Historia dostępu', icon: Icons.history, route: AppRouter.dashboardVdr),
        ],
      ),
      _SidebarItem(
        title: 'Moje kalkulacje',
        icon: Icons.calculate_rounded,
        children: [
          _SidebarItem(title: 'Nowe obliczenie', icon: Icons.add_circle_outline, route: AppRouter.kalkulatorRoi),
          _SidebarItem(title: 'Historia kalkulacji', icon: Icons.history, route: AppRouter.dashboardRoiHistory),
          _SidebarItem(title: 'Porównanie ROI', icon: Icons.compare_arrows, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Analiza z dokumentami', icon: Icons.analytics, route: AppRouter.dashboardRoiHistory),
        ],
      ),
      _SidebarItem(
        title: 'Moje dokumenty',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItem(title: 'Proof of Funds (zatwierdzony)', icon: Icons.verified, route: AppRouter.dashboardDocuments),
          _SidebarItem(title: 'Pobrane operaty', icon: Icons.description, route: AppRouter.dashboardDocuments),
          _SidebarItem(title: 'Pobrane umowy najmu', icon: Icons.description, route: AppRouter.dashboardDocuments),
        ],
      ),
      _SidebarItem(
        title: 'Mój profil',
        icon: AppIcons.profile,
        children: [
          _SidebarItem(title: 'Dane osobowe', icon: Icons.person_outline, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Preferencje inwestycyjne', icon: Icons.tune, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Historia transakcji', icon: Icons.receipt_long, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Status weryfikacji', icon: Icons.verified_user, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItem(
        title: 'Kontakt z doradcą',
        icon: AppIcons.phone,
        route: AppRouter.contact,
      ),
    ];
  }

  List<_SidebarItem> _agentItems() {
    return [
      _SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        children: [
          _SidebarItem(title: 'Podsumowanie moich ofert', icon: Icons.summarize, route: AppRouter.dashboard),
          _SidebarItem(title: 'Aktywność użytkowników', icon: Icons.people, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Statystyki pobrań', icon: Icons.download, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Moje nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItem(title: 'Dodaj nową ofertę', icon: AppIcons.add, route: AppRouter.addListing),
          _SidebarItem(title: 'Aktywne oferty', icon: Icons.check_circle, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Wersje robocze', icon: Icons.edit_note, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Archiwalne', icon: Icons.archive, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItem(
        title: 'Formularze wrzutek',
        icon: Icons.description_outlined,
        children: [
          _SidebarItem(title: 'Grunt', icon: AppIcons.land, route: AppRouter.addListing),
          _SidebarItem(title: 'Lokal (pustostan)', icon: Icons.store, route: AppRouter.addListing),
          _SidebarItem(title: 'Obiekt z najemcą', icon: Icons.business, route: AppRouter.addListing),
        ],
      ),
      _SidebarItem(
        title: 'Dokumentacja',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItem(title: 'Zarządzaj plikami', icon: Icons.folder_open, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Status kompletności', icon: Icons.task_alt, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Logi pobrań', icon: Icons.download_done, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Statystyki',
        icon: AppIcons.statistics,
        children: [
          _SidebarItem(title: 'Moje wyniki', icon: Icons.bar_chart, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Zainteresowanie ofertami', icon: Icons.trending_up, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Wygenerowane leady', icon: Icons.people_outline, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Mój profil',
        icon: AppIcons.profile,
        children: [
          _SidebarItem(title: 'Dane kontaktowe', icon: Icons.contact_phone, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Region działania', icon: Icons.location_on, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Ustawienia powiadomień', icon: Icons.notifications, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItem(
        title: 'Pomoc',
        icon: Icons.help_outline,
        children: [
          _SidebarItem(title: 'Standardy dokumentacji', icon: Icons.menu_book, route: AppRouter.about),
          _SidebarItem(title: 'Wymagania techniczne', icon: Icons.build, route: AppRouter.about),
          _SidebarItem(title: 'Kontakt z Dyrektorem', icon: AppIcons.phone, route: AppRouter.contact),
        ],
      ),
    ];
  }

  List<_SidebarItem> _directorItems() {
    return [
      _SidebarItem(
        title: 'Dashboard regionu',
        icon: Icons.dashboard,
        children: [
          _SidebarItem(title: 'Przegląd województwa', icon: Icons.map, route: AppRouter.dashboard),
          _SidebarItem(title: 'KPI i metryki', icon: Icons.analytics, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Aktywność inwestorów', icon: Icons.people, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Pipeline nieruchomości', icon: Icons.real_estate_agent, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItem(
        title: 'Nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItem(title: 'Wszystkie w województwie', icon: Icons.apartment, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Według agentów', icon: Icons.group, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Według statusu', icon: Icons.filter_list, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Według typu', icon: Icons.category, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Wymagające uwagi', icon: Icons.warning, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItem(
        title: 'Zarządzanie agentami',
        icon: Icons.manage_accounts,
        children: [
          _SidebarItem(title: 'Lista agentów', icon: Icons.people, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Wyniki agentów', icon: Icons.bar_chart, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Dodaj/edytuj agenta', icon: Icons.person_add, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Przypisz obszary', icon: Icons.map, route: AppRouter.dashboardAdminUsers),
        ],
      ),
      _SidebarItem(
        title: 'Weryfikacje VDR',
        icon: Icons.verified_user,
        badge: '0', // TODO: real-time pending count
        children: [
          _SidebarItem(title: 'Oczekujące na zatwierdzenie', icon: Icons.pending, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Zatwierdzone', icon: Icons.check_circle, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Odrzucone', icon: Icons.cancel, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Historia decyzji', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItem(
        title: 'Dokumentacja',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItem(title: 'Kontrola jakości dokumentów', icon: Icons.fact_check, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Logi dostępu VDR', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Raport watermarków', icon: Icons.water_drop, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItem(
        title: 'Raporty i analityki',
        icon: Icons.analytics,
        children: [
          _SidebarItem(title: 'Raport miesięczny', icon: Icons.calendar_month, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Conversion rate', icon: Icons.trending_up, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Źródła leadów', icon: Icons.source, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Czas na platformie', icon: Icons.timer, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Eksport danych', icon: Icons.file_download, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Baza leadów',
        icon: Icons.contacts,
        children: [
          _SidebarItem(title: 'Nowe zapytania "Chcę sprzedać"', icon: Icons.add_comment, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItem(title: 'Przypisane do agentów', icon: Icons.assignment_ind, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItem(title: 'W procesie', icon: Icons.hourglass_empty, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItem(title: 'Zamknięte', icon: Icons.check, route: AppRouter.dashboardAdminSubmissions),
        ],
      ),
      _SidebarItem(
        title: 'Ustawienia regionu',
        icon: Icons.settings,
        children: [
          _SidebarItem(title: 'Parametry województwa', icon: Icons.tune, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Szablony powiadomień', icon: Icons.email, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Workflow zatwierdzania', icon: Icons.account_tree, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItem(
        title: 'Mój profil',
        icon: AppIcons.profile,
        route: AppRouter.dashboardSettings,
      ),
    ];
  }

  List<_SidebarItem> _adminItems() {
    return [
      _SidebarItem(
        title: 'Dashboard globalny',
        icon: Icons.dashboard,
        children: [
          _SidebarItem(title: 'Przegląd całego systemu', icon: Icons.public, route: AppRouter.dashboard),
          _SidebarItem(title: 'Wszystkie województwa', icon: Icons.map, route: AppRouter.dashboard),
          _SidebarItem(title: 'Metryki biznesowe', icon: Icons.analytics, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Alerty systemowe', icon: Icons.warning, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItem(
        title: 'Zarządzanie regionami',
        icon: Icons.map,
        children: [
          _SidebarItem(title: 'Lista województw', icon: Icons.list, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Dodaj/edytuj województwo', icon: Icons.add_location, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Przypisz Dyrektorów', icon: Icons.people, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Statystyki regionalne', icon: Icons.bar_chart, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Użytkownicy',
        icon: Icons.people,
        children: [
          _SidebarItem(title: 'Wszyscy użytkownicy', icon: Icons.group, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Według ról', icon: Icons.admin_panel_settings, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Weryfikacje tożsamości', icon: Icons.verified_user, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Logi aktywności', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Zarządzanie dostępami', icon: Icons.security, route: AppRouter.dashboardAdminUsers),
        ],
      ),
      _SidebarItem(
        title: 'Wszystkie nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItem(title: 'Globalna lista', icon: Icons.apartment, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Kontrola jakości', icon: Icons.fact_check, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Moderacja', icon: Icons.gavel, route: AppRouter.dashboardListings),
          _SidebarItem(title: 'Archiwizacja', icon: Icons.archive, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItem(
        title: 'System VDR',
        icon: Icons.folder_special,
        children: [
          _SidebarItem(title: 'Wszystkie dokumenty', icon: Icons.folder_open, route: AppRouter.dashboardDocuments),
          _SidebarItem(title: 'Logi watermarków', icon: Icons.water_drop, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Naruszenia', icon: Icons.warning, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Zarządzanie uprawnieniami', icon: Icons.lock, route: AppRouter.dashboardAdminUsers),
        ],
      ),
      _SidebarItem(
        title: 'Bezpieczeństwo',
        icon: Icons.security,
        children: [
          _SidebarItem(title: 'Logi bezpieczeństwa', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'NDA tracking', icon: Icons.description, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'IP blacklist', icon: Icons.block, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Próby nieuprawnionego dostępu', icon: Icons.warning, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItem(
        title: 'Raporty i analityki',
        icon: Icons.analytics,
        children: [
          _SidebarItem(title: 'Dashboard BI', icon: Icons.dashboard, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Raporty finansowe (REIT)', icon: Icons.account_balance, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'Analiza konwersji', icon: Icons.trending_up, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'User journey analytics', icon: Icons.route, route: AppRouter.dashboardStatistics),
          _SidebarItem(title: 'A/B testing', icon: Icons.science, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItem(
        title: 'Konfiguracja systemu',
        icon: Icons.settings,
        children: [
          _SidebarItem(title: 'Ustawienia globalne', icon: Icons.tune, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Zarządzanie rolami', icon: Icons.admin_panel_settings, route: AppRouter.dashboardAdminUsers),
          _SidebarItem(title: 'Workflow i procesy', icon: Icons.account_tree, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Integracje (LinkedIn, NIP API)', icon: Icons.integration_instructions, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Szablony email/powiadomień', icon: Icons.email, route: AppRouter.dashboardSettings),
          _SidebarItem(title: 'Parametry watermarkingu', icon: Icons.water_drop, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItem(
        title: 'Narzędzia developerskie',
        icon: Icons.build,
        children: [
          _SidebarItem(title: 'Logi systemowe', icon: Icons.terminal, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Status API', icon: Icons.api, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Backup & restore', icon: Icons.backup, route: AppRouter.dashboardAdminLogs),
          _SidebarItem(title: 'Migracje bazy', icon: Icons.storage, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItem(
        title: 'Baza "Oczekiwanie"',
        icon: Icons.hourglass_empty,
        children: [
          _SidebarItem(title: 'Zgłoszenia do sprzedaży', icon: Icons.real_estate_agent, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItem(title: 'Workflow procesowania', icon: Icons.hub, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItem(title: 'Przypisanie do regionów', icon: Icons.map, route: AppRouter.dashboardAdminSubmissions),
        ],
      ),
      _SidebarItem(
        title: 'Mój profil',
        icon: AppIcons.profile,
        route: AppRouter.dashboardSettings,
      ),
    ];
  }

  String? get _currentPath {
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return widget.currentRoute;
    }
  }

  bool _isRouteActive(String? route, Map<String, String>? queryParams) {
    final path = _currentPath;
    if (path == null || route == null) return false;
    final uri = path.split('?').first;
    if (uri != route) return false;
    if (queryParams == null || queryParams.isEmpty) return true;
    final currentUri = Uri.tryParse(path);
    if (currentUri == null) return false;
    for (final e in queryParams.entries) {
      if (currentUri.queryParameters[e.key] != e.value) return false;
    }
    return true;
  }

  bool _hasActiveChild(_SidebarItem item) {
    if (!item.hasChildren) return _isRouteActive(item.route, item.queryParams);
    for (final c in item.children) {
      if (_hasActiveChild(c)) return true;
    }
    return false;
  }

  Widget _buildItemWidget(
    BuildContext context,
    _SidebarItem item,
    String? parentKey,
  ) {
    if (item.hasChildren) {
      final key = parentKey != null ? '$parentKey.${item.title}' : item.title;
      final isExpanded = _expandedSections.contains(key) || _hasActiveChild(item);
      return ExpansionTile(
        key: ValueKey(key),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedSections.add(key);
            } else {
              _expandedSections.remove(key);
            }
          });
        },
        leading: Icon(
          item.icon,
          color: item.highlighted ? AppColors.accent : AppColors.grey600,
          size: 22,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: item.highlighted ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: item.highlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.badge!,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
                ),
              ),
          ],
        ),
        children: item.children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: _buildLeafItem(context, child),
                ))
            .toList(),
      );
    }

    return _buildLeafItem(context, item);
  }

  Widget _buildLeafItem(BuildContext context, _SidebarItem item) {
    final route = item.route;
    final isSelected = route != null && _isRouteActive(route, item.queryParams);
    final isHighlighted = item.highlighted;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        item.icon,
        color: isSelected || isHighlighted ? AppColors.accent : AppColors.grey600,
        size: 20,
      ),
      title: Text(
        item.title,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected || isHighlighted ? AppColors.accent : AppColors.textPrimary,
          fontWeight: isSelected || isHighlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
      onTap: () {
        if (route != null) {
          final uri = item.queryParams != null && item.queryParams!.isNotEmpty
              ? Uri(path: route, queryParameters: item.queryParams)
              : Uri(path: route);
          context.go(uri.toString());
          if (context.mounted) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: ListTile(
        leading: const Icon(AppIcons.logout, color: AppColors.error),
        title: Text(
          'Wyloguj',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.error,
          ),
        ),
        onTap: () async {
          await auth.signOut();
          if (context.mounted) {
            context.go(AppRouter.home);
          }
        },
      ),
    );
  }
}
