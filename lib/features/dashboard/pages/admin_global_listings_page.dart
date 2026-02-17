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

    return DashboardScaffold(
      title: 'Globalna lista nieruchomości',
      currentRoute: AppRouter.dashboardAdminPanel('listings-global'),
      child: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return _EmptyState();
          }
          return isMobile
              ? _ListingsCardView(listings: listings)
              : _ListingsTableView(listings: listings);
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
  const _ListingsCardView({required this.listings});

  final List<Property> listings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _ListingCardTile(property: listings[index]),
    );
  }
}

/// Kompaktowa karta pojedynczej oferty (mobile).
class _ListingCardTile extends StatelessWidget {
  const _ListingCardTile({required this.property});

  final Property property;

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
            ],
          ),
        ),
      ),
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
  const _ListingsTableView({required this.listings});

  final List<Property> listings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.grey50),
          headingTextStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          dataTextStyle: AppTextStyles.bodySmall,
          columnSpacing: AppSpacing.lg,
          horizontalMargin: AppSpacing.md,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Tytuł')),
            DataColumn(label: Text('Lokalizacja')),
            DataColumn(label: Text('Typ')),
            DataColumn(label: Text('Cena'), numeric: true),
            DataColumn(label: Text('Pow. (m²)'), numeric: true),
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('')),
          ],
          rows: listings.map((p) => _tableRow(context, p)).toList(),
        ),
      ),
    );
  }

  DataRow _tableRow(BuildContext context, Property p) {
    return DataRow(
      cells: [
        DataCell(
          Text(p.id, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              p.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              p.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(p.propertyTypeLabel)),
        DataCell(Text(p.formattedPrice)),
        DataCell(Text(p.area.toStringAsFixed(0))),
        DataCell(Text(_formatDate(p.createdAt))),
        DataCell(
          TextButton(
            onPressed: () => context.go('/property/${p.id}'),
            child: const Text('Otwórz'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}.${d.month}.${d.year}';
  }
}
