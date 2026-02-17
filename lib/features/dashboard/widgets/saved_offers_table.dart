import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/models/saved_offer_model.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../widgets/common/save_to_collection_modal.dart';

/// Widok tabelaryczny zapisanych ofert.
class SavedOffersTable extends ConsumerWidget {
  const SavedOffersTable({
    super.key,
    required this.propertiesWithEntries,
    this.onCompare,
    this.selectedForCompare = const {},
    this.onToggleCompare,
  });

  final List<({Property property, SavedOfferEntry entry})> propertiesWithEntries;
  final VoidCallback? onCompare;
  final Set<String> selectedForCompare;
  final ValueChanged<String>? onToggleCompare;

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7} tyg.';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    return 'teraz';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: propertiesWithEntries.length,
        itemBuilder: (context, i) {
          final item = propertiesWithEntries[i];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Text(item.property.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${item.property.formattedPrice} · ${_timeAgo(item.entry.savedAt)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'open', child: Text('Otwórz')),
                  const PopupMenuItem(value: 'compare', child: Text('Porównaj')),
                  const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  const PopupMenuItem(value: 'remove', child: Text('Usuń')),
                ],
                onSelected: (v) async {
                  if (v == 'open') context.go('/property/${item.property.id}');
                  if (v == 'compare') onToggleCompare?.call(item.property.id);
                  if (v == 'edit') {
                    showSaveToCollectionModal(
                      context: context,
                      property: item.property,
                      existingEntry: item.entry,
                    );
                  }
                  if (v == 'remove') {
                    await ref.read(smartFavoritesProvider.notifier).removeOffer(item.property.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usunięto z zapisanych'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
              ),
              onTap: () => context.go('/property/${item.property.id}'),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.grey50),
        columns: const [
          DataColumn(label: Text('Nazwa')),
          DataColumn(label: Text('Cena')),
          DataColumn(label: Text('ROI')),
          DataColumn(label: Text('Zapisano')),
          DataColumn(label: Text('Akcje')),
        ],
        rows: propertiesWithEntries.map((item) {
          final roi = item.property.roi != null ? '${item.property.roi!.toStringAsFixed(1)}%' : '–';
          final selected = onToggleCompare != null && selectedForCompare.contains(item.property.id);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                onTap: () => context.go('/property/${item.property.id}'),
              ),
              DataCell(Text(item.property.formattedPrice)),
              DataCell(Text(roi)),
              DataCell(Text(_timeAgo(item.entry.savedAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onToggleCompare != null)
                      IconButton(
                        icon: Icon(
                          AppIcons.statistics,
                          size: 20,
                          color: selected ? AppColors.accent : null,
                        ),
                        onPressed: () => onToggleCompare!(item.property.id),
                        tooltip: 'Porównaj',
                      ),
                    IconButton(
                      icon: const Icon(AppIcons.edit, size: 20),
                      onPressed: () {
                        showSaveToCollectionModal(
                          context: context,
                          property: item.property,
                          existingEntry: item.entry,
                        );
                      },
                      tooltip: 'Edytuj',
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.delete, size: 20, color: AppColors.error),
                      onPressed: () async {
                        await ref.read(smartFavoritesProvider.notifier).removeOffer(item.property.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usunięto z zapisanych'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      tooltip: 'Usuń',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
