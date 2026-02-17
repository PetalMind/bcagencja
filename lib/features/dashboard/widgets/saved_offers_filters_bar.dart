import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/saved_offer_model.dart';

enum SavedOffersSort { newest, roiDesc, priceDesc, activity }
enum SavedOffersView { cards, list, table }

class SavedOffersFiltersBar extends StatelessWidget {
  const SavedOffersFiltersBar({
    super.key,
    required this.collections,
    required this.selectedCollectionId,
    required this.onCollectionChanged,
    required this.sort,
    required this.onSortChanged,
    required this.view,
    required this.onViewChanged,
    this.compareCount = 0,
    this.onCompareTap,
    this.onExportTap,
  });

  final List<SavedCollection> collections;
  final String? selectedCollectionId;
  final ValueChanged<String?> onCollectionChanged;
  final SavedOffersSort sort;
  final ValueChanged<SavedOffersSort> onSortChanged;
  final SavedOffersView view;
  final ValueChanged<SavedOffersView> onViewChanged;
  final int compareCount;
  final VoidCallback? onCompareTap;
  final VoidCallback? onExportTap;

  static String sortLabel(SavedOffersSort s) {
    switch (s) {
      case SavedOffersSort.newest:
        return 'Najnowsze';
      case SavedOffersSort.roiDesc:
        return 'ROI ↓';
      case SavedOffersSort.priceDesc:
        return 'Cena ↓';
      case SavedOffersSort.activity:
        return 'Aktywność';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            value: selectedCollectionId,
            decoration: const InputDecoration(
              labelText: 'Kolekcja',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Wszystkie')),
              ...collections.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon} ${c.name}'),
                  )),
            ],
            onChanged: onCollectionChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<SavedOffersSort>(
            value: sort,
            decoration: const InputDecoration(
              labelText: 'Sortuj',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
            items: SavedOffersSort.values
                .map((s) => DropdownMenuItem(value: s, child: Text(sortLabel(s))))
                .toList(),
            onChanged: (v) => v != null ? onSortChanged(v) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ...SavedOffersView.values.map((v) {
                final isSelected = view == v;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(_viewLabel(v)),
                    selected: isSelected,
                    onSelected: (_) => onViewChanged(v),
                  ),
                );
              }),
              const Spacer(),
              if (onExportTap != null)
                IconButton(
                  icon: const Icon(AppIcons.download),
                  onPressed: onExportTap,
                  tooltip: 'Eksportuj zapisane',
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kolekcje:',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<String?>(
              value: selectedCollectionId,
              hint: const Text('Wszystkie'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                ...collections.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.icon} ${c.name}'),
                    )),
              ],
              onChanged: onCollectionChanged,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              'Sortuj:',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<SavedOffersSort>(
              value: sort,
              items: SavedOffersSort.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(sortLabel(s))))
                  .toList(),
              onChanged: (v) => v != null ? onSortChanged(v) : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              'Widok:',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            ...SavedOffersView.values.map((v) {
              final isSelected = view == v;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(_viewLabel(v)),
                  selected: isSelected,
                  onSelected: (_) => onViewChanged(v),
                ),
              );
            }),
            const Spacer(),
            if (compareCount >= 2 && onCompareTap != null)
              TextButton.icon(
                onPressed: onCompareTap,
                icon: const Icon(AppIcons.statistics, size: 18),
                label: Text('Porównaj ($compareCount)'),
              ),
            if (onExportTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(AppIcons.download),
                onPressed: onExportTap,
                tooltip: 'Eksportuj zapisane',
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _viewLabel(SavedOffersView v) {
    switch (v) {
      case SavedOffersView.cards:
        return 'Karty';
      case SavedOffersView.list:
        return 'Lista';
      case SavedOffersView.table:
        return 'Tabela';
    }
  }
}
