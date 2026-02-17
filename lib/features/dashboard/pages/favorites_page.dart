import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/models/saved_offer_model.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/compare_offers_modal.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/saved_offer_card.dart';
import '../widgets/saved_offers_filters_bar.dart';
import '../widgets/saved_offers_table.dart';
import '../widgets/saved_offers_sidebar.dart';

/// Strona „Zapisane oferty” – Smart Favorites: kolekcje, filtry, sortowanie, widoki Karty/Lista/Tabela, porównywarka.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  String? _selectedCollectionId;
  SavedOffersSort _sort = SavedOffersSort.newest;
  SavedOffersView _view = SavedOffersView.cards;
  Set<String> _expandedCollectionIds = {};
  Set<String> _selectedForCompare = {};

  List<Property> _getPropertiesInOrder(List<String> ids) {
    final list = ids
        .map((id) => Property.fromMockId(id))
        .whereType<Property>()
        .toList();
    switch (_sort) {
      case SavedOffersSort.newest:
        break;
      case SavedOffersSort.roiDesc:
        list.sort((a, b) => (b.roi ?? 0).compareTo(a.roi ?? 0));
        break;
      case SavedOffersSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SavedOffersSort.activity:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final favoriteIds = ref.watch(favoritesProvider);
    final smart = ref.watch(smartFavoritesProvider);
    final entries = smart.entries;
    final collections = smart.collections;

    // Filtruj po kolekcji
    List<String> filteredIds = favoriteIds.toList();
    if (_selectedCollectionId != null) {
      filteredIds = filteredIds.where((id) {
        final e = entries[id];
        return e != null && e.collectionIds.contains(_selectedCollectionId);
      }).toList();
    }

    final properties = _getPropertiesInOrder(filteredIds);
    final propertiesWithEntries = properties
        .map((p) => (property: p, entry: entries[p.id] ?? SavedOfferEntry(propertyId: p.id, collectionIds: [], savedAt: DateTime.now())))
        .toList();

    return DashboardScaffold(
      title: 'Zapisane oferty',
      currentRoute: AppRouter.dashboardFavorites,
      actions: [
        if (_selectedForCompare.length >= 2)
          TextButton.icon(
            onPressed: () {
              final list = _selectedForCompare
                  .map((id) => Property.fromMockId(id))
                  .whereType<Property>()
                  .toList();
              if (list.length >= 2) showCompareOffersModal(context: context, properties: list);
            },
            icon: const Icon(AppIcons.statistics, size: 20),
            label: Text('Porównaj (${_selectedForCompare.length})'),
          ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoritesProvider);
          ref.invalidate(smartFavoritesProvider);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              favoriteIds.isEmpty
                  ? 'Brak zapisanych ofert'
                  : 'ZAPISANE OFERTY (${filteredIds.length})',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (favoriteIds.isEmpty)
              DashboardEmptyState(
                title: 'Brak zapisanych ofert',
                subtitle: 'Zapisuj oferty, klikając ikonę serca przy ogłoszeniu lub przycisk „Zapisz ofertę” na stronie szczegółów.',
                actionLabel: 'Przejdź do bazy ofert',
                icon: AppIcons.favorites,
                actionIcon: AppIcons.search,
                onAction: () => context.push(AppRouter.oferty),
              )
            else ...[
              SavedOffersFiltersBar(
                collections: collections,
                selectedCollectionId: _selectedCollectionId,
                onCollectionChanged: (id) => setState(() => _selectedCollectionId = id),
                sort: _sort,
                onSortChanged: (s) => setState(() => _sort = s),
                view: _view,
                onViewChanged: (v) => setState(() => _view = v),
                compareCount: _selectedForCompare.length,
                onCompareTap: _selectedForCompare.length >= 2
                    ? () {
                        final list = _selectedForCompare
                            .map((id) => Property.fromMockId(id))
                            .whereType<Property>()
                            .toList();
                        if (list.length >= 2) showCompareOffersModal(context: context, properties: list);
                      }
                    : null,
                onExportTap: () => _showExportOptions(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filteredIds.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      'Brak ofert w wybranej kolekcji.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else if (_view == SavedOffersView.table)
                SavedOffersTable(
                  propertiesWithEntries: propertiesWithEntries,
                  selectedForCompare: _selectedForCompare,
                  onToggleCompare: (id) {
                    setState(() {
                      if (_selectedForCompare.contains(id)) {
                        _selectedForCompare = Set.from(_selectedForCompare)..remove(id);
                      } else if (_selectedForCompare.length < 5) {
                        _selectedForCompare = Set.from(_selectedForCompare)..add(id);
                      }
                    });
                  },
                  onCompare: _selectedForCompare.length >= 2
                      ? () {
                          final list = _selectedForCompare
                              .map((id) => Property.fromMockId(id))
                              .whereType<Property>()
                              .toList();
                          if (list.length >= 2) showCompareOffersModal(context: context, properties: list);
                        }
                      : null,
                )
              else
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGroupedOrFlatList(
                            context,
                            ref,
                            collections,
                            propertiesWithEntries,
                            true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SavedOffersSidebar(
                            savedCount: filteredIds.length,
                            compareCount: _selectedForCompare.length,
                            recommendations: [
                              Property.mock(10),
                              Property.mock(11),
                              Property.mock(12),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildGroupedOrFlatList(
                              context,
                              ref,
                              collections,
                              propertiesWithEntries,
                              false,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          SizedBox(
                            width: 280,
                            child: SavedOffersSidebar(
                              savedCount: filteredIds.length,
                              compareCount: _selectedForCompare.length,
                              recommendations: [
                                Property.mock(10),
                                Property.mock(11),
                                Property.mock(12),
                              ],
                            ),
                          ),
                        ],
                      ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Eksportuj zapisane',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Format:',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF (prezentacja)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eksport PDF – wkrótce'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel (tabela danych)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eksport Excel – wkrótce'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('CSV (do analizy)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eksport CSV – wkrótce'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Anuluj'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedOrFlatList(
    BuildContext context,
    WidgetRef ref,
    List<SavedCollection> collections,
    List<({Property property, SavedOfferEntry entry})> propertiesWithEntries,
    bool isMobile,
  ) {
    // Grupowanie po kolekcji: jeśli wybrana konkretna kolekcja, nie grupuj
    if (_selectedCollectionId != null) {
      return _view == SavedOffersView.list
          ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: propertiesWithEntries.length,
              itemBuilder: (context, i) {
                final item = propertiesWithEntries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SavedOfferCard(
                    property: item.property,
                    entry: item.entry,
                    compact: true,
                    onCompare: () {
                      setState(() {
                        if (_selectedForCompare.contains(item.property.id)) {
                          _selectedForCompare = Set.from(_selectedForCompare)..remove(item.property.id);
                        } else if (_selectedForCompare.length < 5) {
                          _selectedForCompare = Set.from(_selectedForCompare)..add(item.property.id);
                        }
                      });
                    },
                  ),
                );
              },
            )
          : Column(
              children: propertiesWithEntries
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: SavedOfferCard(
                          property: item.property,
                          entry: item.entry,
                          onCompare: () {
                            setState(() {
                              if (_selectedForCompare.contains(item.property.id)) {
                                _selectedForCompare = Set.from(_selectedForCompare)..remove(item.property.id);
                              } else if (_selectedForCompare.length < 5) {
                                _selectedForCompare = Set.from(_selectedForCompare)..add(item.property.id);
                              }
                            });
                          },
                        ),
                      ))
                  .toList(),
            );
    }

    // Grupuj po kolekcjach
    final byCollection = <String, List<({Property property, SavedOfferEntry entry})>>{};
    for (final item in propertiesWithEntries) {
      for (final cid in item.entry.collectionIds) {
        byCollection.putIfAbsent(cid, () => []).add(item);
      }
    }
    // Oferty bez żadnej kolekcji
    final noCollection = propertiesWithEntries.where((e) => e.entry.collectionIds.isEmpty).toList();
    if (noCollection.isNotEmpty) byCollection['_none'] = noCollection;

    final orderedCollections = collections.where((c) => byCollection.containsKey(c.id)).toList();
    if (byCollection.containsKey('_none')) orderedCollections.add(SavedCollection(id: '_none', name: 'Bez kolekcji', icon: '📁'));

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: orderedCollections.map((c) {
        final items = byCollection[c.id]!;
        final isCollapsed = _expandedCollectionIds.contains(c.id);
        final isExpanded = !isCollapsed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _expandedCollectionIds = Set.from(_expandedCollectionIds);
                  if (isExpanded) {
                    _expandedCollectionIds.add(c.id);
                  } else {
                    _expandedCollectionIds.remove(c.id);
                  }
                }),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text('${c.icon} ', style: AppTextStyles.titleMedium),
                      Text(
                        '${c.name.toUpperCase()} (${items.length})',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
                      ),
                      const Spacer(),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _view == SavedOffersView.list
                        ? SavedOfferCard(
                            property: item.property,
                            entry: item.entry,
                            compact: true,
                            onCompare: () {
                              setState(() {
                                if (_selectedForCompare.contains(item.property.id)) {
                                  _selectedForCompare = Set.from(_selectedForCompare)..remove(item.property.id);
                                } else if (_selectedForCompare.length < 5) {
                                  _selectedForCompare = Set.from(_selectedForCompare)..add(item.property.id);
                                }
                              });
                            },
                          )
                        : SavedOfferCard(
                            property: item.property,
                            entry: item.entry,
                            onCompare: () {
                              setState(() {
                                if (_selectedForCompare.contains(item.property.id)) {
                                  _selectedForCompare = Set.from(_selectedForCompare)..remove(item.property.id);
                                } else if (_selectedForCompare.length < 5) {
                                  _selectedForCompare = Set.from(_selectedForCompare)..add(item.property.id);
                                }
                              });
                            },
                          ),
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        );
      }).toList(),
    );
  }
}
