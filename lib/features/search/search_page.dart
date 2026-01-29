import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/search_filters_model.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import 'widgets/search_bar_commercial.dart';
import 'widgets/advanced_filters_panel.dart';
import 'widgets/filter_tags.dart';
import 'widgets/price_range_slider.dart';
import 'widgets/filter_accordion.dart';

/// Stałe: typy nieruchomości komercyjnych (magazyny, hale, biurowce, bloki mieszkalne, tereny przemysłowe + podkategorie).
const Map<String, String> kPropertyTypeLabels = {
  'office': 'Budynki biurowe',
  'warehouse': 'Magazyny',
  'retail': 'Lokale handlowe',
  'industrial': 'Tereny / Hale przemysłowe',
  'hotel': 'Hotele i obiekty',
  'land': 'Działki inwestycyjne',
};

/// Status oferty: na sprzedaż, w negocjacji, sprzedane.
const Map<String, String> kListingStatusLabels = {
  'for_sale': 'Na sprzedaż',
  'in_negotiation': 'W negocjacji',
  'sold': 'Sprzedane',
};

/// Opcje sortowania.
const Map<String, String> kSortByLabels = {
  'price_asc': 'Cena: rosnąco',
  'price_desc': 'Cena: malejąco',
  'date_desc': 'Data: najnowsze',
  'date_asc': 'Data: najstarsze',
  'area_desc': 'Powierzchnia: malejąco',
  'area_asc': 'Powierzchnia: rosnąco',
  'popularity': 'Popularność',
};

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchFilters _filters = SearchFilters();
  bool _advancedFiltersExpanded = false;

  String get _sortDropdownValue {
    if (_filters.sortBy == null) return 'date_desc';
    if (_filters.sortBy == 'popularity') return 'popularity';
    return '${_filters.sortBy}_${_filters.sortOrder ?? 'desc'}';
  }

  void _applySearch() {
    final params = _buildQueryParams();
    final query = params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    final path = query.isEmpty ? AppRouter.searchResults : '${AppRouter.searchResults}?$query';
    context.go(path);
  }

  Map<String, String?> _buildQueryParams() {
    return {
      'keyword': _filters.keyword,
      'location': _filters.location?.isNotEmpty == true ? _filters.location : (_filters.city ?? _filters.voivodeship),
      'city': _filters.city,
      'postalCode': _filters.postalCode,
      'voivodeship': _filters.voivodeship,
      'minPrice': _filters.minPrice?.toString(),
      'maxPrice': _filters.maxPrice?.toString(),
      'propertyType': _filters.propertyType,
      'propertyTypes': _filters.propertyTypes.isNotEmpty ? _filters.propertyTypes.join(',') : null,
      'minArea': _filters.minArea?.toString(),
      'maxArea': _filters.maxArea?.toString(),
      'minPlotArea': _filters.minPlotArea?.toString(),
      'maxPlotArea': _filters.maxPlotArea?.toString(),
      'listingStatus': _filters.listingStatus,
      'sortBy': _filters.sortBy,
      'sortOrder': _filters.sortOrder,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: false),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nagłówek sekcji
            _buildHeader(),
            // Główny pasek wyszukiwania
            _buildSearchBarSection(),
            // Szybkie filtry: typ nieruchomości, status, cena, powierzchnia
            _buildQuickFilters(isMobile),
            // Tagi aktywnych filtrów
            if (_filters.hasActiveFilters) _buildFilterTagsSection(),
            // Filtry zaawansowane (rozwijane)
            _buildAdvancedSection(isMobile),
            // Sortowanie + przycisk Szukaj
            _buildSortAndSubmit(isMobile),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      color: AppColors.backgroundGrey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Szukaj nieruchomości komercyjnych',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lokalizacja, typ obiektu, zakres cenowy i powierzchnia — wyniki w czasie rzeczywistym.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: SearchBarCommercial(
          keyword: _filters.keyword,
          location: _filters.location ?? _filters.city,
          onKeywordChanged: (v) => setState(() => _filters = _filters.copyWith(keyword: v)),
          onLocationChanged: (v) => setState(() => _filters = _filters.copyWith(location: v)),
          onSearch: _applySearch,
        ),
      ),
    );
  }

  Widget _buildQuickFilters(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typ nieruchomości', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kPropertyTypeLabels.entries.map((e) {
                final isSelected = _filters.propertyType == e.key || _filters.propertyTypes.contains(e.key);
                return FilterChip(
                  label: Text(e.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _filters = _filters.copyWith(propertyTypes: [..._filters.propertyTypes, e.key]);
                      } else {
                        _filters = _filters.copyWith(
                          propertyType: _filters.propertyType == e.key ? null : _filters.propertyType,
                          propertyTypes: _filters.propertyTypes.where((t) => t != e.key).toList(),
                        );
                      }
                    });
                  },
                  selectedColor: AppColors.accent.withOpacity(0.2),
                  checkmarkColor: AppColors.accent,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Status oferty', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kListingStatusLabels.entries.map((e) {
                final isSelected = _filters.listingStatus == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _filters = _filters.copyWith(listingStatus: selected ? e.key : null));
                  },
                  selectedColor: AppColors.accent.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Cena + Powierzchnia w jednym wierszu na desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 500;
                return narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilterAccordion(
                            title: 'Zakres cenowy (zł)',
                            icon: AppIcons.price,
                            initiallyExpanded: _filters.minPrice != null || _filters.maxPrice != null,
                            child: PriceRangeSlider(
                              min: _filters.minPrice ?? 0,
                              max: _filters.maxPrice ?? 5000000,
                              minLimit: 0,
                              maxLimit: 50000000,
                              onChanged: (min, max) =>
                                  setState(() => _filters = _filters.copyWith(minPrice: min, maxPrice: max)),
                            ),
                          ),
                          FilterAccordion(
                            title: 'Powierzchnia (m²)',
                            icon: AppIcons.area,
                            initiallyExpanded: _filters.minArea != null || _filters.maxArea != null,
                            child: _buildAreaFields(),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FilterAccordion(
                              title: 'Zakres cenowy (zł)',
                              icon: AppIcons.price,
                              initiallyExpanded: _filters.minPrice != null || _filters.maxPrice != null,
                              child: PriceRangeSlider(
                                min: _filters.minPrice ?? 0,
                                max: _filters.maxPrice ?? 5000000,
                                minLimit: 0,
                                maxLimit: 50000000,
                                onChanged: (min, max) =>
                                    setState(() => _filters = _filters.copyWith(minPrice: min, maxPrice: max)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: FilterAccordion(
                              title: 'Powierzchnia (m²)',
                              icon: AppIcons.area,
                              initiallyExpanded: _filters.minArea != null || _filters.maxArea != null,
                              child: _buildAreaFields(),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min. pow. użytkowa',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _filters = _filters.copyWith(minArea: double.tryParse(v))),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max. pow. użytkowa',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _filters = _filters.copyWith(maxArea: double.tryParse(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min. pow. działki',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _filters = _filters.copyWith(minPlotArea: double.tryParse(v))),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max. pow. działki',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _filters = _filters.copyWith(maxPlotArea: double.tryParse(v))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTagsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: FilterTags(
          filters: _filters,
          onFilterRemoved: (f) => setState(() => _filters = f),
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _advancedFiltersExpanded = !_advancedFiltersExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.filter,
                        color: AppColors.accent,
                        size: AppSpacing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filtry zaawansowane',
                        style: AppTextStyles.titleMedium,
                      ),
                      const Spacer(),
                      Icon(
                        _advancedFiltersExpanded ? AppIcons.collapse : AppIcons.expand,
                        color: AppColors.grey600,
                      ),
                    ],
                  ),
                ),
              ),
              if (_advancedFiltersExpanded) ...[
                const Divider(height: 1),
                SizedBox(
                  height: 420,
                  child: AdvancedFiltersPanel(
                    initialFilters: _filters,
                    onFiltersChanged: (f) => setState(() => _filters = f),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortAndSubmit(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
        child: Row(
          children: [
            Expanded(
              flex: isMobile ? 1 : 2,
              child: DropdownButtonFormField<String>(
                value: _sortDropdownValue,
                decoration: const InputDecoration(
                  labelText: 'Sortuj według',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: kSortByLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final parts = value.split('_');
                  setState(() => _filters = _filters.copyWith(
                    sortBy: parts[0],
                    sortOrder: parts.length > 1 ? parts[1] : 'desc',
                  ));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.icon(
              onPressed: _applySearch,
              icon: const Icon(AppIcons.search, size: 20),
              label: const Text('Pokaż wyniki'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                textStyle: AppTextStyles.buttonMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
