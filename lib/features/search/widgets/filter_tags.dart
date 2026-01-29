import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/search_filters_model.dart';

const Map<String, String> _propertyTypeLabels = {
  'office': 'Biurowe',
  'warehouse': 'Magazyny',
  'retail': 'Handlowe',
  'industrial': 'Przemysłowe',
  'hotel': 'Hotele',
  'land': 'Działki',
};

const Map<String, String> _listingStatusLabels = {
  'for_sale': 'Na sprzedaż',
  'in_negotiation': 'W negocjacji',
  'sold': 'Sprzedane',
};

class FilterTags extends StatelessWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFilterRemoved;
  
  const FilterTags({
    super.key,
    required this.filters,
    required this.onFilterRemoved,
  });

  @override
  Widget build(BuildContext context) {
    if (!filters.hasActiveFilters) {
      return const SizedBox.shrink();
    }
    
    final tags = <Widget>[];
    
    if (filters.keyword != null && filters.keyword!.isNotEmpty) {
      tags.add(_buildTag(
        'Słowa: ${filters.keyword}',
        () => onFilterRemoved(filters.copyWith(keyword: '')),
      ));
    }
    
    if (filters.location != null && filters.location!.isNotEmpty) {
      tags.add(_buildTag(
        'Lokalizacja: ${filters.location}',
        () => onFilterRemoved(filters.copyWith(location: '')),
      ));
    }
    
    if ((filters.minPrice != null && filters.minPrice! > 0) ||
        (filters.maxPrice != null && filters.maxPrice! > 0)) {
      final min = filters.minPrice != null && filters.minPrice! > 0
          ? '${(filters.minPrice! / 1000).toStringAsFixed(0)}k'
          : '0';
      final max = filters.maxPrice != null && filters.maxPrice! > 0
          ? '${(filters.maxPrice! / 1000).toStringAsFixed(0)}k zł'
          : '∞';
      tags.add(_buildTag(
        'Cena: $min - $max',
        () => onFilterRemoved(filters.copyWith(minPrice: null, maxPrice: null)),
      ));
    }
    
    if (filters.propertyType != null && filters.propertyType!.isNotEmpty) {
      final label = _propertyTypeLabels[filters.propertyType] ?? filters.propertyType;
      tags.add(_buildTag(
        'Typ: $label',
        () => onFilterRemoved(filters.copyWith(propertyType: null)),
      ));
    }
    
    for (final t in filters.propertyTypes) {
      if (t.isEmpty) continue;
      final label = _propertyTypeLabels[t] ?? t;
      tags.add(_buildTag(
        'Typ: $label',
        () => onFilterRemoved(filters.copyWith(
          propertyTypes: filters.propertyTypes.where((x) => x != t).toList(),
        )),
      ));
    }
    
    if (filters.listingStatus != null && filters.listingStatus!.isNotEmpty) {
      final label = _listingStatusLabels[filters.listingStatus] ?? filters.listingStatus;
      tags.add(_buildTag(
        'Status: $label',
        () => onFilterRemoved(filters.copyWith(listingStatus: null)),
      ));
    }
    
    if (filters.minArea != null || filters.maxArea != null) {
      final a = filters.minArea != null ? '${filters.minArea!.toStringAsFixed(0)}' : '0';
      final b = filters.maxArea != null ? '${filters.maxArea!.toStringAsFixed(0)} m²' : '∞';
      tags.add(_buildTag(
        'Pow.: $a - $b',
        () => onFilterRemoved(filters.copyWith(minArea: null, maxArea: null)),
      ));
    }
    
    if (filters.minPlotArea != null || filters.maxPlotArea != null) {
      final a = filters.minPlotArea != null ? '${filters.minPlotArea!.toStringAsFixed(0)}' : '0';
      final b = filters.maxPlotArea != null ? '${filters.maxPlotArea!.toStringAsFixed(0)} m²' : '∞';
      tags.add(_buildTag(
        'Działka: $a - $b',
        () => onFilterRemoved(filters.copyWith(minPlotArea: null, maxPlotArea: null)),
      ));
    }
    
    if (filters.onlyWithPhotos) {
      tags.add(_buildTag(
        'Ze zdjęciami',
        () => onFilterRemoved(filters.copyWith(onlyWithPhotos: false)),
      ));
    }
    
    if (filters.fromOwner) {
      tags.add(_buildTag(
        'Od właściciela',
        () => onFilterRemoved(filters.copyWith(fromOwner: false)),
      ));
    }
    
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tags,
    );
  }
  
  Widget _buildTag(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: AppTextStyles.labelSmall,
      ),
      deleteIcon: const Icon(AppIcons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.accent.withOpacity(0.1),
      deleteIconColor: AppColors.accent,
    );
  }
}
