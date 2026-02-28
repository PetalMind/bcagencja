import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../../../widgets/common/app_data_grid.dart';

final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Stream listy ofert z Firestore (kolekcja listings). Tylko dla panelu admina.
final _globalListingsProvider = StreamProvider<List<Property>>((ref) {
  return ref.read(_adminServiceProvider).streamGlobalListings();
});

/// Panel admina: globalna lista nieruchomości – responsywna (karty na mobile, tabela na desktop).
class AdminGlobalListingsPage extends ConsumerWidget {
  const AdminGlobalListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(_globalListingsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    final adminService = ref.read(_adminServiceProvider);

    return DashboardScaffold(
      title: 'Globalna lista nieruchomości',
      currentRoute: AppRouter.dashboardAdminPanel('listings-global'),
      child: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return _EmptyState();
          }
          return isMobile
              ? _ListingsCardView(listings: listings, adminService: adminService)
              : _ListingsTableView(listings: listings, adminService: adminService);
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Błąd ładowania listy: ${err.toString()}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.office, size: 64, color: AppColors.grey400),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Brak ofert w systemie',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widok listy kart – mobile.
class _ListingsCardView extends StatelessWidget {
  const _ListingsCardView({required this.listings, required this.adminService});

  final List<Property> listings;
  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _ListingCardTile(
        property: listings[index],
        adminService: adminService,
      ),
    );
  }
}

/// Kompaktowa karta pojedynczej oferty (mobile) z akcjami admina.
class _ListingCardTile extends StatelessWidget {
  const _ListingCardTile({required this.property, required this.adminService});

  final Property property;
  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.go('/property/${property.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(AppIcons.location, size: 14, color: AppColors.grey500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.location,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _Chip(label: property.propertyTypeLabel),
                            _Chip(label: '${property.area.toStringAsFixed(0)} m²'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        property.formattedPrice,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _AdminActionBar(
                property: property,
                adminService: adminService,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pasek akcji admina: Zobacz, Edytuj, Zmień status, Usuń.
class _AdminActionBar extends StatelessWidget {
  const _AdminActionBar({
    required this.property,
    required this.adminService,
    this.compact = false,
  });

  final Property property;
  final AdminService adminService;
  final bool compact;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń ogłoszenie'),
        content: Text(
          'Czy na pewno chcesz usunąć ofertę „${property.title}”? Ta operacja jest nieodwracalna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final err = await adminService.deleteListing(property.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err != null ? 'Błąd: $err' : 'Oferta została usunięta'),
        backgroundColor: err != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final err = await adminService.updateListingStatus(property.id, status);
    if (!context.mounted) return;
    final label = status == 'published' ? 'Opublikowano' : 'Ukryto ofertę';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err != null ? 'Błąd: $err' : label),
        backgroundColor: err != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/property/${property.id}'),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Zobacz'),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRouter.propertyEdit(property.id)),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edytuj'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Więcej akcji',
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              } else {
                _updateStatus(context, value);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'published', child: Text('Opublikuj')),
              const PopupMenuItem(value: 'draft', child: Text('Ukryj (wersja robocza)')),
              const PopupMenuItem(value: 'archived', child: Text('Archiwizuj')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('Usuń', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => context.go('/property/${property.id}'),
          child: const Text('Zobacz'),
        ),
        TextButton(
          onPressed: () => context.push(AppRouter.propertyEdit(property.id)),
          child: const Text('Edytuj'),
        ),
        PopupMenuButton<String>(
          child: const Text('Status'),
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context);
            } else {
              _updateStatus(context, value);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'published', child: Text('Opublikuj')),
            const PopupMenuItem(value: 'draft', child: Text('Ukryj (wersja robocza)')),
            const PopupMenuItem(value: 'archived', child: Text('Archiwizuj')),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text('Usuń', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Widok tabeli – desktop.
class _ListingsTableView extends StatelessWidget {
  const _ListingsTableView({required this.listings, required this.adminService});

  final List<Property> listings;
  final AdminService adminService;

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return AppDataGrid(
      allowSorting: true,
      allowMultiColumnSorting: true,
      allowColumnsResizing: true,
      showPagination: listings.length > 20,
      pageSize: 20,
      columns: const [
        AppDataGridColumn(name: 'id', label: 'ID', width: 90),
        AppDataGridColumn(name: 'title', label: 'Tytuł', minimumWidth: 180),
        AppDataGridColumn(name: 'location', label: 'Lokalizacja', minimumWidth: 140),
        AppDataGridColumn(name: 'type', label: 'Typ', width: 120),
        AppDataGridColumn(name: 'price', label: 'Cena', width: 130),
        AppDataGridColumn(name: 'area', label: 'Pow. (m²)', width: 90),
        AppDataGridColumn(name: 'date', label: 'Data', width: 90),
        AppDataGridColumn(name: 'actions', label: 'Akcje', width: 230, sortable: false),
      ],
      sortValues: listings.map((p) => [
        p.id,
        p.title,
        p.location,
        p.propertyTypeLabel,
        p.price,
        p.area,
        p.createdAt.millisecondsSinceEpoch,
        0,
      ]).toList(),
      rows: listings.map((p) => [
        Text(p.id, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(p.location, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(p.propertyTypeLabel),
        Text(p.formattedPrice),
        Text(p.area.toStringAsFixed(0)),
        Text(_formatDate(p.createdAt)),
        _AdminActionBar(property: p, adminService: adminService, compact: false),
      ]).toList(),
    );
  }
}
