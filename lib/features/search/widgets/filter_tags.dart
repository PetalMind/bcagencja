import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/search_filters_model.dart';

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
    
    if (filters.location != null) {
      tags.add(_buildTag(
        'Lokalizacja: ${filters.location}',
        () => onFilterRemoved(filters.copyWith(location: '')),
      ));
    }
    
    if (filters.minPrice != null || filters.maxPrice != null) {
      String priceText = 'Cena: ';
      if (filters.minPrice != null) {
        priceText += '${filters.minPrice!.toStringAsFixed(0)}';
      }
      priceText += ' - ';
      if (filters.maxPrice != null) {
        priceText += '${filters.maxPrice!.toStringAsFixed(0)}';
      }
      tags.add(_buildTag(
        priceText,
        () => onFilterRemoved(filters.copyWith(minPrice: 0, maxPrice: 0)),
      ));
    }
    
    if (filters.propertyType != null) {
      tags.add(_buildTag(
        'Typ: ${filters.propertyType}',
        () => onFilterRemoved(filters.copyWith(propertyType: '')),
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
