import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/state/providers/dashboard_providers.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../widgets/common/watermarked_image.dart';
import '../../../widgets/common/save_to_collection_modal.dart';

class SimilarListings extends ConsumerWidget {
  final Property property;

  const SimilarListings({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final similarAsync = ref.watch(similarListingsProvider(property));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : 0,
          ),
          child: Text(
            'Podobne oferty',
            style: AppTextStyles.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        similarAsync.when(
          data: (similarProperties) {
            if (similarProperties.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
                child: Text(
                  'Brak podobnych ofert w tej kategorii.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            return SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.md : 0,
                ),
                itemCount: similarProperties.length,
                itemBuilder: (context, index) {
                  final similarProperty = similarProperties[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: AppSpacing.md),
                    child: _SimilarListingCard(property: similarProperty),
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                width: 280,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: _SimilarListingCardShimmer(),
              ),
            ),
          ),
          error: (err, stack) => Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
            child: Text(
              'Nie udało się załadować podobnych ofert.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimilarListingCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 100,
                  color: AppColors.grey200,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 16,
                  width: double.infinity,
                  color: AppColors.grey200,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 14,
                  width: 120,
                  color: AppColors.grey200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarListingCard extends ConsumerWidget {
  final Property property;

  const _SimilarListingCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isOwnListing = user != null && property.ownerId == user.id;
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(property.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: () => context.go('/property/${property.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.grey200,
                    child: WatermarkedImage(
                      child: Image.network(
                        property.mainImage ?? (property.images.isNotEmpty ? property.images.first : ''),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          AppIcons.image,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isOwnListing)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? AppIcons.favorites : AppIcons.favoriteBorder,
                        size: 20,
                      ),
                      color: isFavorite ? AppColors.accent : AppColors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                      ),
                      onPressed: () {
                        if (isFavorite) {
                          ref
                              .read(smartFavoritesProvider.notifier)
                              .removeOffer(property.id);
                        } else {
                          final entry =
                              ref.read(smartFavoritesProvider).entryFor(property.id);
                          showSaveToCollectionModal(
                            context: context,
                            property: property,
                            existingEntry: entry,
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
            // Content – teaser-safe: yield/range zamiast ceny absolutnej
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (property.teaserPriceDisplay != null)
                    Text(
                      property.teaserPriceDisplay!,
                      style: AppTextStyles.priceMedium,
                    )
                  else
                    Text(
                      'Zapytaj o cenę',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    property.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(AppIcons.location, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(AppIcons.area, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(
                        '${property.area.toStringAsFixed(0)}m²',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(AppIcons.rooms, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(
                        '${property.rooms}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
