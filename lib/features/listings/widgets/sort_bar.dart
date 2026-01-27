import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

enum SortOption {
  dateDesc,
  dateAsc,
  priceDesc,
  priceAsc,
  areaDesc,
  areaAsc,
  popularity,
}

class SortBar extends StatelessWidget {
  final int resultsCount;
  final SortOption selectedSort;
  final Function(SortOption) onSortChanged;
  final VoidCallback? onSaveSearch;
  
  const SortBar({
    super.key,
    required this.resultsCount,
    required this.selectedSort,
    required this.onSortChanged,
    this.onSaveSearch,
  });

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return 'Najnowsze';
      case SortOption.dateAsc:
        return 'Najstarsze';
      case SortOption.priceDesc:
        return 'Cena (malejąco)';
      case SortOption.priceAsc:
        return 'Cena (rosnąco)';
      case SortOption.areaDesc:
        return 'Powierzchnia (malejąco)';
      case SortOption.areaAsc:
        return 'Powierzchnia (rosnąco)';
      case SortOption.popularity:
        return 'Popularność';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Znaleziono: $resultsCount ofert',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          DropdownButton<SortOption>(
            value: selectedSort,
            icon: const Icon(AppIcons.sort),
            underline: Container(),
            items: SortOption.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(_getSortLabel(option)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSortChanged(value);
              }
            },
          ),
          if (onSaveSearch != null) ...[
            const SizedBox(width: AppSpacing.md),
            TextButton.icon(
              onPressed: onSaveSearch,
              icon: const Icon(AppIcons.save),
              label: const Text('Zapisz wyszukiwanie'),
            ),
          ],
        ],
      ),
    );
  }
}
