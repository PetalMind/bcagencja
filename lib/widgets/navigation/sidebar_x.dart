import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/auth/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';
import '../../features/dashboard/dashboard_strings.dart';

/// Dane jednej pozycji menu (może mieć dzieci – rozwijalna sekcja).
class _SidebarItemData {
  const _SidebarItemData({
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
  final List<_SidebarItemData> children;
  final String? badge;
  final bool highlighted;
  final Map<String, String>? queryParams;

  bool get hasChildren => children.isNotEmpty;
}

/// Avatar użytkownika w headerze sidebara; klikalny gdy użytkownik może edytować profil (wybór zdjęcia).
class _SidebarXAvatar extends ConsumerWidget {
  const _SidebarXAvatar({
    required this.user,
    required this.roleLevel,
    required this.onPhotoUpdated,
  });

  final AppUser? user;
  final UserRoleLevel roleLevel;
  final VoidCallback onPhotoUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = user != null && RolePermissions.canEditProfile(roleLevel);
    final authService = ref.read(authServiceProvider);
    final child = Container(
      width: AppSpacing.avatarSize,
      height: AppSpacing.avatarSize,
      decoration: BoxDecoration(
        color: user?.photoUrl != null ? AppColors.grey800 : AppColors.accent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: user?.photoUrl != null
            ? Image(
                image: NetworkImage(user!.photoUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(AppIcons.profile, size: AppSpacing.iconMd, color: AppColors.white),
              )
            : const Icon(AppIcons.profile, size: AppSpacing.iconMd, color: AppColors.white),
      ),
    );
    if (!canEdit) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAvatarPicker(context, authService, onPhotoUpdated),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1),
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showAvatarPicker(
    BuildContext context,
    AuthService authService,
    VoidCallback onPhotoUpdated,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _AvatarPickerPage(
          authService: authService,
          onDone: () {
            onPhotoUpdated();
            navigator.pop();
            messenger.showSnackBar(
              const SnackBar(content: Text('Zdjęcie profilowe zaktualizowane')),
            );
          },
          onError: (e) {
            navigator.pop();
            messenger.showSnackBar(SnackBar(content: Text('Błąd: $e')));
          },
        ),
      ),
    );
  }
}

/// Strona wyboru zdjęcia (galeria / aparat) i uploadu.
class _AvatarPickerPage extends StatelessWidget {
  const _AvatarPickerPage({
    required this.authService,
    required this.onDone,
    required this.onError,
  });

  final AuthService authService;
  final VoidCallback onDone;
  final void Function(Object) onError;

  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !context.mounted) return;
    final bytes = await xFile.readAsBytes();
    try {
      await authService.updateUserPhoto(bytes);
      if (context.mounted) onDone();
    } catch (e) {
      if (context.mounted) onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zmień zdjęcie profilowe'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Z galerii'),
                onTap: () => _pickAndUpload(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Zrób zdjęcie'),
                onTap: () => _pickAndUpload(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sidebar z rozwijalnym podmenu (jak oryginalny [Sidebar]).
/// Zawartość menu: role, pozycje, header, footer; sekcje z dziećmi są zwijane/rozwijane.
/// Obsługuje tryb zwinięty [isCollapsed] – pokazuje tylko ikony.
class SidebarXShell extends ConsumerStatefulWidget {
  final String? currentRoute;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;

  const SidebarXShell({
    super.key,
    this.currentRoute,
    this.isCollapsed = false,
    this.onToggleCollapsed,
  });

  @override
  ConsumerState<SidebarXShell> createState() => _SidebarXShellState();
}

class _SidebarXShellState extends ConsumerState<SidebarXShell> {
  final Set<String> _expandedSections = {};

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

  /// Czy w poddrzewie tej pozycji jest jedyna aktywna (activeItemKey).
  bool _sectionContainsActiveKey(
    _SidebarItemData item,
    String? parentKey,
    String? activeItemKey,
  ) {
    if (activeItemKey == null) return false;
    final key = _itemKey(parentKey, item.title);
    if (item.hasChildren) {
      for (final c in item.children) {
        if (_sectionContainsActiveKey(c, key, activeItemKey)) return true;
      }
      return false;
    }
    return key == activeItemKey;
  }

  String _itemKey(String? parentKey, String title) {
    return parentKey != null ? '$parentKey.$title' : title;
  }

  /// Zwraca klucz jedynej pozycji uznawanej za aktywną (pierwsza w kolejności menu
  /// pasująca do bieżącej ścieżki). Dzięki temu przy wielu pozycjach z tym samym
  /// route (np. /dashboard/listings) podświetlana jest tylko jedna.
  String? _getActiveItemKey(List<_SidebarItemData> items, String? parentKey) {
    for (final item in items) {
      final key = _itemKey(parentKey, item.title);
      if (item.hasChildren) {
        final k = _getActiveItemKey(item.children, key);
        if (k != null) return k;
      } else {
        if (item.route != null && _isRouteActive(item.route, item.queryParams)) {
          return key;
        }
      }
    }
    return null;
  }

  static const double _tileRadius = AppSpacing.radiusSm;
  static const double _tilePaddingH = AppSpacing.md;
  static const double _tilePaddingV = AppSpacing.sidebarTilePaddingV;
  static BorderRadius get _radiusLeftOnly =>
      BorderRadius.only(bottomLeft: Radius.circular(_tileRadius));
  static BorderRadius get _radiusLeftOnlyMd =>
      BorderRadius.only(bottomLeft: Radius.circular(AppSpacing.radiusMd));

  List<_SidebarItemData> _menuItemsForRole(UserRoleLevel roleLevel, AppUser? user) {
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

  static List<_SidebarItemData> _investorLevel1Items() {
    return [
      _SidebarItemData(title: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRouter.dashboard),
      _SidebarItemData(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
      _SidebarItemData(title: 'Zapisane', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
      _SidebarItemData(title: 'Kalkulator ROI', icon: Icons.bar_chart_rounded, route: AppRouter.kalkulatorRoi),
      _SidebarItemData(title: 'Weryfikacja tożsamości', icon: Icons.verified_user_outlined, route: AppRouter.weryfikacja, highlighted: true),
      _SidebarItemData(title: 'Ustawienia', icon: Icons.settings_outlined, route: AppRouter.dashboardSettings),
      _SidebarItemData(title: 'Kontakt', icon: AppIcons.phone, route: AppRouter.contact),
    ];
  }

  static List<_SidebarItemData> _investorLevel2Items() {
    return [
      _SidebarItemData(title: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRouter.dashboard),
      _SidebarItemData(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
      _SidebarItemData(title: 'Zapisane', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
      _SidebarItemData(title: 'Kalkulator ROI', icon: Icons.bar_chart_rounded, route: AppRouter.kalkulatorRoi),
      _SidebarItemData(title: 'Moje dokumenty', icon: Icons.folder_outlined, route: AppRouter.dashboardDocuments),
      _SidebarItemData(title: 'Ustawienia', icon: Icons.settings_outlined, route: AppRouter.dashboardSettings),
      _SidebarItemData(title: 'Kontakt', icon: AppIcons.phone, route: AppRouter.contact),
    ];
  }

  static List<_SidebarItemData> _investorLevel3Items() {
    return [
      _SidebarItemData(
        title: 'Przeglądaj oferty',
        icon: Icons.home_rounded,
        children: [
          _SidebarItemData(title: 'Wszystkie nieruchomości', icon: Icons.apartment, route: AppRouter.oferty),
          _SidebarItemData(title: 'Grunty', icon: AppIcons.land, route: AppRouter.oferty, queryParams: {'typ': 'land'}),
          _SidebarItemData(title: 'Lokale (pustostany)', icon: Icons.store, route: AppRouter.oferty, queryParams: {'typ': 'vacant'}),
          _SidebarItemData(title: 'Obiekty z najemcą', icon: Icons.business, route: AppRouter.oferty, queryParams: {'typ': 'tenanted'}),
          _SidebarItemData(title: 'Zapisane/Ulubione', icon: AppIcons.favorites, route: AppRouter.dashboardFavorites),
          _SidebarItemData(title: 'Moje zgłoszenia (dodane oferty)', icon: Icons.real_estate_agent_outlined, route: AppRouter.dashboardMySubmissions),
        ],
      ),
      _SidebarItemData(
        title: 'Virtual Data Room',
        icon: Icons.folder_special,
        children: [
          _SidebarItemData(title: 'Dostępne VDR', icon: Icons.folder_open, route: AppRouter.dashboardVdr),
          _SidebarItemData(title: 'Pobrane dokumenty', icon: Icons.download_done, route: AppRouter.dashboardVdr),
          _SidebarItemData(title: 'Historia dostępu', icon: Icons.history, route: AppRouter.dashboardVdr),
        ],
      ),
      _SidebarItemData(
        title: 'Moje kalkulacje',
        icon: Icons.calculate_rounded,
        children: [
          _SidebarItemData(title: 'Nowe obliczenie', icon: Icons.add_circle_outline, route: AppRouter.kalkulatorRoi),
          _SidebarItemData(title: 'Historia kalkulacji', icon: Icons.history, route: AppRouter.dashboardRoiHistory),
          _SidebarItemData(title: 'Porównanie ROI', icon: Icons.compare_arrows, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Analiza z dokumentami', icon: Icons.analytics, route: AppRouter.dashboardRoiHistory),
        ],
      ),
      _SidebarItemData(
        title: 'Moje dokumenty',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItemData(title: 'Proof of Funds (zatwierdzony)', icon: Icons.verified, route: AppRouter.dashboardDocuments),
          _SidebarItemData(title: 'Pobrane operaty', icon: Icons.description, route: AppRouter.dashboardDocuments),
          _SidebarItemData(title: 'Pobrane umowy najmu', icon: Icons.description, route: AppRouter.dashboardDocuments),
        ],
      ),
      _SidebarItemData(
        title: 'Mój profil',
        icon: AppIcons.profile,
        children: [
          _SidebarItemData(title: 'Dane osobowe', icon: Icons.person_outline, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Preferencje inwestycyjne', icon: Icons.tune, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Historia transakcji', icon: Icons.receipt_long, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Status weryfikacji', icon: Icons.verified_user, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItemData(title: 'Kontakt z doradcą', icon: AppIcons.phone, route: AppRouter.contact),
    ];
  }

  static List<_SidebarItemData> _agentItems() {
    return [
      _SidebarItemData(
        title: 'Dashboard',
        icon: Icons.dashboard,
        children: [
          _SidebarItemData(title: 'Podsumowanie moich ofert', icon: Icons.summarize, route: AppRouter.dashboard),
          _SidebarItemData(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
          _SidebarItemData(title: 'Aktywność użytkowników', icon: Icons.people, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Statystyki pobrań', icon: Icons.download, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItemData(
        title: 'Moje nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItemData(title: 'Dodaj nową ofertę', icon: AppIcons.add, route: AppRouter.chceSprzedac),
          _SidebarItemData(title: 'Moje zgłoszenia (dodane oferty)', icon: Icons.real_estate_agent_outlined, route: AppRouter.dashboardMySubmissions),
          _SidebarItemData(title: 'Aktywne oferty', icon: Icons.check_circle, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Wersje robocze', icon: Icons.edit_note, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Archiwalne', icon: Icons.archive, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItemData(
        title: 'Formularze wrzutek',
        icon: Icons.description_outlined,
        children: [
          _SidebarItemData(title: 'Grunt', icon: AppIcons.land, route: AppRouter.chceSprzedac),
          _SidebarItemData(title: 'Lokal (pustostan)', icon: Icons.store, route: AppRouter.chceSprzedac),
          _SidebarItemData(title: 'Obiekt z najemcą', icon: Icons.business, route: AppRouter.chceSprzedac),
        ],
      ),
      _SidebarItemData(
        title: 'Dokumentacja',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItemData(title: 'Zarządzaj plikami', icon: Icons.folder_open, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Status kompletności', icon: Icons.task_alt, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Logi pobrań', icon: Icons.download_done, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItemData(
        title: 'Statystyki',
        icon: AppIcons.statistics,
        children: [
          _SidebarItemData(title: 'Moje wyniki', icon: Icons.bar_chart, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Zainteresowanie ofertami', icon: Icons.trending_up, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Wygenerowane leady', icon: Icons.people_outline, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItemData(
        title: 'Mój profil',
        icon: AppIcons.profile,
        children: [
          _SidebarItemData(title: 'Dane kontaktowe', icon: Icons.contact_phone, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Region działania', icon: Icons.location_on, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Ustawienia powiadomień', icon: Icons.notifications, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItemData(
        title: 'Pomoc',
        icon: Icons.help_outline,
        children: [
          _SidebarItemData(title: 'Standardy dokumentacji', icon: Icons.menu_book, route: AppRouter.about),
          _SidebarItemData(title: 'Wymagania techniczne', icon: Icons.build, route: AppRouter.about),
          _SidebarItemData(title: 'Kontakt z Dyrektorem', icon: AppIcons.phone, route: AppRouter.contact),
        ],
      ),
    ];
  }

  static List<_SidebarItemData> _directorItems() {
    return [
      _SidebarItemData(
        title: 'Dashboard regionu',
        icon: Icons.dashboard,
        children: [
          _SidebarItemData(title: 'Przegląd województwa', icon: Icons.map, route: AppRouter.dashboard),
          _SidebarItemData(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
          _SidebarItemData(title: 'KPI i metryki', icon: Icons.analytics, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Aktywność inwestorów', icon: Icons.people, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Pipeline nieruchomości', icon: Icons.real_estate_agent, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItemData(
        title: 'Nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItemData(title: 'Wszystkie w województwie', icon: Icons.apartment, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Według agentów', icon: Icons.group, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Według statusu', icon: Icons.filter_list, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Według typu', icon: Icons.category, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Wymagające uwagi', icon: Icons.warning, route: AppRouter.dashboardListings),
        ],
      ),
      _SidebarItemData(
        title: 'Zarządzanie agentami',
        icon: Icons.manage_accounts,
        children: [
          _SidebarItemData(title: 'Lista agentów', icon: Icons.people, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Wyniki agentów', icon: Icons.bar_chart, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Dodaj/edytuj agenta', icon: Icons.person_add, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Przypisz obszary', icon: Icons.map, route: AppRouter.dashboardAdminUsers),
        ],
      ),
      _SidebarItemData(
        title: 'Weryfikacje VDR',
        icon: Icons.verified_user,
        badge: '0',
        children: [
          _SidebarItemData(title: 'Oczekujące na zatwierdzenie', icon: Icons.pending, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Zatwierdzone', icon: Icons.check_circle, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Odrzucone', icon: Icons.cancel, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Historia decyzji', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItemData(
        title: 'Dokumentacja',
        icon: Icons.folder_outlined,
        children: [
          _SidebarItemData(title: 'Kontrola jakości dokumentów', icon: Icons.fact_check, route: AppRouter.dashboardListings),
          _SidebarItemData(title: 'Logi dostępu VDR', icon: Icons.history, route: AppRouter.dashboardAdminLogs),
          _SidebarItemData(title: 'Raport watermarków', icon: Icons.water_drop, route: AppRouter.dashboardAdminLogs),
        ],
      ),
      _SidebarItemData(
        title: 'Raporty i analityki',
        icon: Icons.analytics,
        children: [
          _SidebarItemData(title: 'Raport miesięczny', icon: Icons.calendar_month, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Conversion rate', icon: Icons.trending_up, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Źródła leadów', icon: Icons.source, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Czas na platformie', icon: Icons.timer, route: AppRouter.dashboardStatistics),
          _SidebarItemData(title: 'Eksport danych', icon: Icons.file_download, route: AppRouter.dashboardStatistics),
        ],
      ),
      _SidebarItemData(
        title: 'Baza leadów',
        icon: Icons.contacts,
        children: [
          _SidebarItemData(title: 'Nowe zapytania "Chcę sprzedać"', icon: Icons.add_comment, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItemData(title: 'Przypisane do agentów', icon: Icons.assignment_ind, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItemData(title: 'W procesie', icon: Icons.hourglass_empty, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItemData(title: 'Zamknięte', icon: Icons.check, route: AppRouter.dashboardAdminSubmissions),
        ],
      ),
      _SidebarItemData(
        title: 'Ustawienia regionu',
        icon: Icons.settings,
        children: [
          _SidebarItemData(title: 'Parametry województwa', icon: Icons.tune, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Szablony powiadomień', icon: Icons.email, route: AppRouter.dashboardSettings),
          _SidebarItemData(title: 'Workflow zatwierdzania', icon: Icons.account_tree, route: AppRouter.dashboardSettings),
        ],
      ),
      _SidebarItemData(title: 'Mój profil', icon: AppIcons.profile, route: AppRouter.dashboardSettings),
    ];
  }

  static List<_SidebarItemData> _adminItems() {
    return [
      _SidebarItemData(
        title: 'Dashboard globalny',
        icon: Icons.dashboard,
        children: [
          _SidebarItemData(title: 'Przegląd całego systemu', icon: Icons.dashboard_outlined, route: AppRouter.dashboardAdminOverview),
          _SidebarItemData(title: 'Przeglądaj oferty', icon: Icons.search_rounded, route: AppRouter.oferty),
          _SidebarItemData(title: 'Wszystkie województwa', icon: Icons.map, route: AppRouter.dashboardAdminPanel('regions-map')),
          _SidebarItemData(title: 'Metryki biznesowe', icon: Icons.analytics, route: AppRouter.dashboardAdminPanel('metrics')),
          _SidebarItemData(title: 'Alerty systemowe', icon: Icons.warning, route: AppRouter.dashboardAdminPanel('alerts')),
        ],
      ),
      _SidebarItemData(
        title: 'Zarządzanie regionami',
        icon: Icons.map,
        children: [
          _SidebarItemData(title: 'Lista województw', icon: Icons.list, route: AppRouter.dashboardAdminPanel('regions-list')),
          _SidebarItemData(title: 'Dodaj/edytuj województwo', icon: Icons.add_location, route: AppRouter.dashboardAdminPanel('regions-edit')),
          _SidebarItemData(title: 'Przypisz Dyrektorów', icon: Icons.people, route: AppRouter.dashboardAdminPanel('regions-directors')),
          _SidebarItemData(title: 'Statystyki regionalne', icon: Icons.bar_chart, route: AppRouter.dashboardAdminPanel('regions-stats')),
        ],
      ),
      _SidebarItemData(
        title: 'Użytkownicy',
        icon: Icons.people,
        children: [
          _SidebarItemData(title: 'Wszyscy użytkownicy', icon: Icons.group, route: AppRouter.dashboardAdminUsers),
          _SidebarItemData(title: 'Według ról', icon: Icons.admin_panel_settings, route: AppRouter.dashboardAdminPanel('users-roles')),
          _SidebarItemData(title: 'Weryfikacje tożsamości', icon: Icons.verified_user, route: AppRouter.dashboardAdminPanel('users-verifications')),
          _SidebarItemData(title: 'Logi aktywności', icon: Icons.history, route: AppRouter.dashboardAdminPanel('users-activity')),
          _SidebarItemData(title: 'Zarządzanie dostępami', icon: Icons.security, route: AppRouter.dashboardAdminPanel('users-access')),
        ],
      ),
      _SidebarItemData(
        title: 'Wszystkie nieruchomości',
        icon: AppIcons.office,
        children: [
          _SidebarItemData(title: 'Globalna lista', icon: Icons.apartment, route: AppRouter.dashboardAdminPanel('listings-global')),
          _SidebarItemData(title: 'Kontrola jakości', icon: Icons.fact_check, route: AppRouter.dashboardAdminPanel('listings-quality')),
          _SidebarItemData(title: 'Moderacja', icon: Icons.gavel, route: AppRouter.dashboardAdminPanel('listings-moderation')),
          _SidebarItemData(title: 'Archiwizacja', icon: Icons.archive, route: AppRouter.dashboardAdminPanel('listings-archive')),
        ],
      ),
      _SidebarItemData(
        title: 'System VDR',
        icon: Icons.folder_special,
        children: [
          _SidebarItemData(title: 'Wszystkie dokumenty', icon: Icons.folder_open, route: AppRouter.dashboardAdminPanel('vdr-documents')),
          _SidebarItemData(title: 'Logi watermarków', icon: Icons.water_drop, route: AppRouter.dashboardAdminPanel('vdr-watermarks')),
          _SidebarItemData(title: 'Naruszenia', icon: Icons.warning, route: AppRouter.dashboardAdminPanel('vdr-violations')),
          _SidebarItemData(title: 'Zarządzanie uprawnieniami', icon: Icons.lock, route: AppRouter.dashboardAdminPanel('vdr-permissions')),
        ],
      ),
      _SidebarItemData(
        title: 'Bezpieczeństwo',
        icon: Icons.security,
        children: [
          _SidebarItemData(title: 'Logi bezpieczeństwa', icon: Icons.history, route: AppRouter.dashboardAdminPanel('security-logs')),
          _SidebarItemData(title: 'NDA tracking', icon: Icons.description, route: AppRouter.dashboardAdminPanel('security-nda')),
          _SidebarItemData(title: 'IP blacklist', icon: Icons.block, route: AppRouter.dashboardAdminPanel('security-ip')),
          _SidebarItemData(title: 'Próby nieuprawnionego dostępu', icon: Icons.warning, route: AppRouter.dashboardAdminPanel('security-unauthorized')),
        ],
      ),
      _SidebarItemData(
        title: 'Raporty i analityki',
        icon: Icons.analytics,
        children: [
          _SidebarItemData(title: 'Dashboard BI', icon: Icons.dashboard, route: AppRouter.dashboardAdminPanel('reports-bi')),
          _SidebarItemData(title: 'Raporty finansowe (REIT)', icon: Icons.account_balance, route: AppRouter.dashboardAdminPanel('reports-financial')),
          _SidebarItemData(title: 'Analiza konwersji', icon: Icons.trending_up, route: AppRouter.dashboardAdminPanel('reports-conversion')),
          _SidebarItemData(title: 'User journey analytics', icon: Icons.route, route: AppRouter.dashboardAdminPanel('reports-journey')),
          _SidebarItemData(title: 'A/B testing', icon: Icons.science, route: AppRouter.dashboardAdminPanel('reports-ab')),
        ],
      ),
      _SidebarItemData(
        title: 'Konfiguracja systemu',
        icon: Icons.settings,
        children: [
          _SidebarItemData(title: 'Ustawienia globalne', icon: Icons.tune, route: AppRouter.dashboardAdminPanel('config-global')),
          _SidebarItemData(title: 'Zarządzanie rolami', icon: Icons.admin_panel_settings, route: AppRouter.dashboardAdminPanel('config-roles')),
          _SidebarItemData(title: 'Workflow i procesy', icon: Icons.account_tree, route: AppRouter.dashboardAdminPanel('config-workflow')),
          _SidebarItemData(title: 'Integracje (LinkedIn, NIP API)', icon: Icons.integration_instructions, route: AppRouter.dashboardAdminPanel('config-integrations')),
          _SidebarItemData(title: 'Szablony email/powiadomień', icon: Icons.email, route: AppRouter.dashboardAdminPanel('config-templates')),
          _SidebarItemData(title: 'Parametry watermarkingu', icon: Icons.water_drop, route: AppRouter.dashboardAdminPanel('config-watermarking')),
        ],
      ),
      _SidebarItemData(
        title: 'Narzędzia developerskie',
        icon: Icons.build,
        children: [
          _SidebarItemData(title: 'Logi systemowe', icon: Icons.terminal, route: AppRouter.dashboardAdminPanel('dev-logs')),
          _SidebarItemData(title: 'Status API', icon: Icons.api, route: AppRouter.dashboardAdminPanel('dev-api')),
          _SidebarItemData(title: 'Backup & restore', icon: Icons.backup, route: AppRouter.dashboardAdminPanel('dev-backup')),
          _SidebarItemData(title: 'Migracje bazy', icon: Icons.storage, route: AppRouter.dashboardAdminPanel('dev-migrations')),
        ],
      ),
      _SidebarItemData(
        title: 'Baza "Oczekiwanie"',
        icon: Icons.hourglass_empty,
        children: [
          _SidebarItemData(title: 'Zgłoszenia do sprzedaży', icon: Icons.real_estate_agent, route: AppRouter.dashboardAdminSubmissions),
          _SidebarItemData(title: 'Workflow procesowania', icon: Icons.hub, route: AppRouter.dashboardAdminPanel('submissions-workflow')),
          _SidebarItemData(title: 'Przypisanie do regionów', icon: Icons.map, route: AppRouter.dashboardAdminPanel('submissions-regions')),
        ],
      ),
      _SidebarItemData(title: 'Mój profil', icon: AppIcons.profile, route: AppRouter.dashboardSettings),
    ];
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    UserRoleLevel roleLevel,
    AppUser? user,
  ) {
    final items = _menuItemsForRole(roleLevel, user);
    final activeItemKey = _getActiveItemKey(items, null);
    final favoritesCount = ref.watch(favoritesProvider).length;
    final showVdrCta = user != null &&
        (roleLevel == UserRoleLevel.investorBasic || roleLevel == UserRoleLevel.investorVerified) &&
        !RolePermissions.canAccessVdr(roleLevel);

    final widgets = <Widget>[];
    var vdrCtaAdded = false;
    var dividerAdded = false;
    for (final item in items) {
      if (!dividerAdded && item.hasChildren) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(height: 1, color: AppColors.borderLight),
        ));
        dividerAdded = true;
      }
      final isZapisane = item.title == 'Zapisane' || item.title.contains('Ulubione') || item.title.contains('Zapisane');
      final badge = item.badge ?? (isZapisane && favoritesCount > 0 ? '$favoritesCount' : null);
      final itemWithBadge = badge != null
          ? _SidebarItemData(
              title: item.title,
              icon: item.icon,
              route: item.route,
              children: item.children,
              badge: badge,
              highlighted: item.highlighted,
              queryParams: item.queryParams,
            )
          : item;
      widgets.add(_buildItemWidget(context, itemWithBadge, null, activeItemKey));
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

  Widget _buildItemWidget(
    BuildContext context,
    _SidebarItemData item,
    String? parentKey,
    String? activeItemKey,
  ) {
    if (item.hasChildren) {
      final key = _itemKey(parentKey, item.title);
      final isExpanded = _expandedSections.contains(key) ||
          _sectionContainsActiveKey(item, parentKey, activeItemKey);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(key);
                  } else {
                    _expandedSections.add(key);
                  }
                });
              },
              borderRadius: _radiusLeftOnly,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _tilePaddingH, vertical: _tilePaddingV),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: item.highlighted ? AppColors.accent : AppColors.grey600,
                      size: AppSpacing.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: item.highlighted ? AppColors.accent : AppColors.textPrimary,
                          fontWeight: item.highlighted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (item.badge != null) _buildBadge(item.badge!),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: AppSpacing.iconSm,
                      color: AppColors.grey500,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            ...item.children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: _buildLeafItem(context, child, key, activeItemKey),
              ),
            ),
        ],
      );
    }
    return _buildLeafItem(context, item, parentKey, activeItemKey);
  }

  Widget _buildBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLeafItem(
    BuildContext context,
    _SidebarItemData item,
    String? parentKey,
    String? activeItemKey,
  ) {
    final route = item.route;
    final itemKey = _itemKey(parentKey, item.title);
    final isSelected = activeItemKey != null && itemKey == activeItemKey;
    final isHighlighted = item.highlighted;
    final isActive = isSelected || isHighlighted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != null) {
              final uri = item.queryParams != null && item.queryParams!.isNotEmpty
                  ? Uri(path: route, queryParameters: item.queryParams)
                  : Uri(path: route);
              if (context.mounted && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                Navigator.of(context).pop();
              }
              if (context.mounted) context.go(uri.toString());
            }
          },
          borderRadius: _radiusLeftOnly,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: _tilePaddingH, vertical: _tilePaddingV),
            decoration: BoxDecoration(
              color: isActive ? AppColors.grey100 : null,
              borderRadius: _radiusLeftOnly,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive ? AppColors.accent : AppColors.grey600,
                  size: AppSpacing.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (item.badge != null) _buildBadge(item.badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
    final items = _menuItemsForRole(roleLevel, user);
    final isCollapsed = widget.isCollapsed;

    if (roleLevel == UserRoleLevel.guest || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.white,
      child: Column(
        children: [
          _buildHeader(context, roleLevel, user),
          Expanded(
            child: isCollapsed
                ? _buildCollapsedMenu(context, roleLevel, user)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    children: _buildMenuItems(context, roleLevel, user),
                  ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildCollapsedMenu(BuildContext context, UserRoleLevel roleLevel, AppUser? user) {
    final items = _menuItemsForRole(roleLevel, user);
    final activeItemKey = _getActiveItemKey(items, null);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: items.map((item) {
        final key = _itemKey(null, item.title);
        final isActive = activeItemKey != null &&
            (key == activeItemKey || _sectionContainsActiveKey(item, null, activeItemKey));
        return Tooltip(
          message: item.title,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 300),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final route = item.hasChildren ? item.children.first.route : item.route;
                final qp = item.hasChildren ? item.children.first.queryParams : item.queryParams;
                if (route != null) {
                  final uri = qp != null && qp.isNotEmpty
                      ? Uri(path: route, queryParameters: qp)
                      : Uri(path: route);
                  if (context.mounted) context.go(uri.toString());
                }
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.grey100 : null,
                  border: isActive
                      ? const Border(left: BorderSide(color: AppColors.accent, width: 3))
                      : null,
                ),
                child: Icon(
                  item.icon,
                  size: AppSpacing.iconMd,
                  color: isActive ? AppColors.accent : AppColors.grey600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context, UserRoleLevel roleLevel, AppUser? user) {
    final isCollapsed = widget.isCollapsed;
    final isInvestor = roleLevel == UserRoleLevel.investorBasic ||
        roleLevel == UserRoleLevel.investorVerified ||
        roleLevel == UserRoleLevel.investorVip;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? DashboardStrings.defaultDisplayName;

    if (isCollapsed) {
      return Container(
        width: double.infinity,
        color: AppColors.primaryDark,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: _SidebarXAvatar(
                  user: user,
                  roleLevel: roleLevel,
                  onPhotoUpdated: () => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildToggleButton(),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SidebarXAvatar(
                  user: user,
                  roleLevel: roleLevel,
                  onPhotoUpdated: () => setState(() {}),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        RolePermissions.label(roleLevel),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                      if (isInvestor) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _verificationBadgeForLevel(roleLevel),
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildToggleButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    final isCollapsed = widget.isCollapsed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onToggleCollapsed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            color: AppColors.white.withValues(alpha: 0.7),
            size: AppSpacing.iconMd,
          ),
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

  Widget _buildVdrCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Material(
        color: AppColors.ctaHighlight.withValues(alpha: 0.15),
        borderRadius: _radiusLeftOnlyMd,
        child: InkWell(
          onTap: () {
            context.go(AppRouter.weryfikacja);
            if (context.mounted && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
              Navigator.of(context).pop();
            }
          },
          borderRadius: _radiusLeftOnlyMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch, size: AppSpacing.iconSm, color: AppColors.ctaHighlight),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DashboardStrings.vdrCtaTitleSidebar,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.ctaHighlight,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DashboardStrings.vdrCtaDescriptionSidebar,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
    final showVdrCta = user != null &&
        (roleLevel == UserRoleLevel.investorBasic || roleLevel == UserRoleLevel.investorVerified) &&
        !RolePermissions.canAccessVdr(roleLevel);
    final isCollapsed = widget.isCollapsed;

    if (isCollapsed) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: Tooltip(
          message: 'Wyloguj',
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await auth.signOut();
                if (!context.mounted) return;
                context.go(AppRouter.home);
              },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: const Icon(AppIcons.logout, color: AppColors.error, size: AppSpacing.iconSm),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVdrCta) _buildVdrCta(context),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await auth.signOut();
                if (!context.mounted) return;
                context.go(AppRouter.home);
              },
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppSpacing.radiusSm)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sidebarTilePaddingV),
                child: Row(
                  children: [
                    const Icon(AppIcons.logout, color: AppColors.error, size: AppSpacing.iconSm),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Wyloguj',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
