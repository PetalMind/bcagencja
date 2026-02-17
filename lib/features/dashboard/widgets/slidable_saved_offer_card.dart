import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/models/saved_offer_model.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../widgets/common/save_to_collection_modal.dart';
import 'saved_offer_card.dart';

/// Karta zapisanej oferty z gestami: swipe left (Usuń / Udostępnij), swipe right (Porównaj), long press (menu).
class SlidableSavedOfferCard extends ConsumerWidget {
  const SlidableSavedOfferCard({
    super.key,
    required this.property,
    required this.entry,
    required this.onCompare,
    required this.onRemove,
    this.compact = false,
  });

  final Property property;
  final SavedOfferEntry entry;
  final VoidCallback? onCompare;
  final VoidCallback? onRemove;
  final bool compact;

  void _share(BuildContext context) {
    final url = Uri.base.origin;
    Share.share(
      '${property.title}\n${property.location}\n$url/property/${property.id}',
      subject: property.title,
    );
  }

  void _showLongPressMenu(BuildContext context, WidgetRef ref) {
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
                property.title,
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(AppIcons.statistics),
                title: const Text('Porównaj'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCompare?.call();
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.share),
                title: const Text('Udostępnij'),
                onTap: () {
                  Navigator.pop(ctx);
                  _share(context);
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.edit),
                title: const Text('Edytuj'),
                onTap: () {
                  Navigator.pop(ctx);
                  showSaveToCollectionModal(
                    context: context,
                    property: property,
                    existingEntry: entry,
                  );
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.delete, color: AppColors.error),
                title: const Text('Usuń z zapisanych', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(smartFavoritesProvider.notifier).removeOffer(property.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usunięto z zapisanych ofert'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  onRemove?.call();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(property.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          if (onCompare != null)
            SlidableAction(
              onPressed: (_) => onCompare!(),
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
              icon: AppIcons.statistics,
              label: 'Porównaj',
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => _share(context),
            backgroundColor: AppColors.grey600,
            foregroundColor: AppColors.white,
            icon: AppIcons.share,
            label: 'Udostępnij',
          ),
          SlidableAction(
            onPressed: (_) async {
              await ref.read(smartFavoritesProvider.notifier).removeOffer(property.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usunięto z zapisanych ofert'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              onRemove?.call();
            },
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            icon: AppIcons.delete,
            label: 'Usuń',
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () => _showLongPressMenu(context, ref),
        child: SavedOfferCard(
          property: property,
          entry: entry,
          onCompare: onCompare,
          compact: compact,
        ),
      ),
    );
  }
}
