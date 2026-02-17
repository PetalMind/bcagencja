import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/models/saved_offer_model.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../widgets/common/save_to_collection_modal.dart';
import '../../listings/widgets/listing_card.dart';

/// Karta zapisanej oferty: property + notatka, data zapisu, kolekcje, akcje (Porównaj, Udostępnij, Edytuj, Usuń).
class SavedOfferCard extends ConsumerWidget {
  const SavedOfferCard({
    super.key,
    required this.property,
    required this.entry,
    this.onCompare,
    this.compact = false,
  });

  final Property property;
  final SavedOfferEntry entry;
  final VoidCallback? onCompare;
  final bool compact;

  static String _timeAgo(DateTime savedAt) {
    final now = DateTime.now();
    final diff = now.difference(savedAt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7} tyg. temu';
    if (diff.inDays >= 1) return '${diff.inDays} dni temu';
    if (diff.inHours >= 1) return '${diff.inHours} h temu';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min temu';
    return 'teraz';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smart = ref.watch(smartFavoritesProvider);
    final collectionNames = entry.collectionIds.map((id) {
      final list = smart.collections.where((e) => e.id == id).toList();
      final c = list.isEmpty ? null : list.first;
      return c != null ? '${c.icon} ${c.name}' : null;
    }).whereType<String>().toList();
    final savedAgo = _timeAgo(entry.savedAt);

    if (compact) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: InkWell(
          onTap: () => context.go('/property/${property.id}'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _ActionsRow(
                      property: property,
                      entry: entry,
                      onCompare: onCompare,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${property.formattedPrice} · ${property.area.toStringAsFixed(0)} m²',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '"${entry.note}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Text(
                  'Zapisano: $savedAgo',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingCard(property: property),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs, right: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (collectionNames.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: collectionNames
                      .map((n) => Chip(
                            label: Text(n, style: AppTextStyles.labelSmall),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              Text(
                'Zapisano: $savedAgo',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              if (property.roi != null) ...[
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => context.push(AppRouter.kalkulatorRoi),
                  child: Row(
                    children: [
                      Icon(AppIcons.statistics, size: 14, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'ROI ${property.roi!.toStringAsFixed(1)}% · Przelicz w kalkulatorze',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ],
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        entry.note!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _ActionsRow(
                property: property,
                entry: entry,
                onCompare: onCompare,
                compact: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow({
    required this.property,
    required this.entry,
    this.onCompare,
    this.compact = false,
  });

  final Property property;
  final SavedOfferEntry entry;
  final VoidCallback? onCompare;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (onCompare != null)
          TextButton.icon(
            onPressed: onCompare,
            icon: const Icon(AppIcons.statistics, size: 18),
            label: const Text('Porównaj'),
          ),
        TextButton.icon(
          onPressed: () async {
            final url = '${Uri.base.origin}/property/${property.id}';
            await Share.share(
              '${property.title}\n${property.location}\n$url',
              subject: property.title,
            );
          },
          icon: const Icon(AppIcons.share, size: 18),
          label: const Text('Udostępnij'),
        ),
        TextButton.icon(
          onPressed: () {
            showSaveToCollectionModal(
              context: context,
              property: property,
              existingEntry: entry,
            );
          },
          icon: const Icon(AppIcons.edit, size: 18),
          label: const Text('Edytuj'),
        ),
        TextButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Usuń z zapisanych'),
                content: Text(
                  'Czy na pewno usunąć ofertę „${property.title}” z zapisanych?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Anuluj'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Usuń', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await ref.read(smartFavoritesProvider.notifier).removeOffer(property.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usunięto z zapisanych ofert'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          icon: const Icon(AppIcons.delete, size: 18),
          label: const Text('Usuń'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }
}
