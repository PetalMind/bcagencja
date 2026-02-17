import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../widgets/common/watermarked_image.dart';
import '../../../widgets/common/save_to_collection_modal.dart';
import '../../property/widgets/property_gallery.dart';

class ListingGridTile extends ConsumerStatefulWidget {
  final Property property;

  const ListingGridTile({
    super.key,
    required this.property,
  });

  @override
  ConsumerState<ListingGridTile> createState() => _ListingGridTileState();
}

class _ListingGridTileState extends ConsumerState<ListingGridTile> {
  bool _isHovered = false;
  int _cardImageIndex = 0;

  String _formatListingDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    final days = diff.inDays.abs();
    if (days == 0) return 'Dzisiaj';
    if (days == 1) return 'Wczoraj';
    if (days < 7) return '$days dni temu';
    if (days < 30) return '${(days / 7).floor()} tyg. temu';
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildCardImage(Property property) {
    final images = property.images;
    if (images.isEmpty) {
      return const Center(
        child: Icon(AppIcons.image, size: 32, color: AppColors.grey400),
      );
    }
    final index = _cardImageIndex.clamp(0, images.length - 1);
    final url = images.length > 1
        ? images[index]
        : (property.mainImage ?? images[0]);
    return WatermarkedImage(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: AppColors.grey200,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, _, _) => const Icon(
          AppIcons.image,
          size: 32,
          color: AppColors.grey400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(property.id);
    final semanticLabel =
        '${property.formattedPrice}, ${property.title}. ${isFavorite ? 'W ulubionych.' : ''}';

    return Semantics(
      label: semanticLabel,
      button: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Card(
            elevation: _isHovered ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: InkWell(
              onTap: () => context.go('/property/${property.id}'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image – tap otwiera lightbox, hover – mini-galeria
                  GestureDetector(
                    onTap: () {
                      if (property.images.isEmpty) return;
                      showGalleryLightbox(
                        context,
                        images: property.images,
                        initialIndex: _cardImageIndex.clamp(0, property.images.length - 1),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusMd),
                          ),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            color: AppColors.grey200,
                            child: _buildCardImage(property),
                          ),
                        ),
                        if (property.images.length > 1)
                        Positioned(
                          bottom: AppSpacing.xs,
                          right: AppSpacing.xs,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.6),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  AppIcons.image,
                                  size: 12,
                                  color: AppColors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${property.images.length}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: Semantics(
                          label: isFavorite
                              ? 'Usuń z ulubionych'
                              : 'Dodaj do ulubionych',
                          button: true,
                          child: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? AppIcons.favorites
                                  : AppIcons.favoriteBorder,
                              size: 18,
                              color:
                                  isFavorite ? AppColors.accent : AppColors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.black.withValues(alpha: 0.5),
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(28, 28),
                            ),
                            onPressed: () {
                              if (isFavorite) {
                                ref
                                    .read(smartFavoritesProvider.notifier)
                                    .removeOffer(property.id);
                              } else {
                                final entry = ref
                                    .read(smartFavoritesProvider)
                                    .entryFor(property.id);
                                showSaveToCollectionModal(
                                  context: context,
                                  property: property,
                                  existingEntry: entry,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                        if (_isHovered && property.images.length > 1) ...[
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(AppIcons.chevronLeft,
                                    color: AppColors.white, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      AppColors.black.withValues(alpha: 0.5),
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(28, 28),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _cardImageIndex = (_cardImageIndex - 1) %
                                        property.images.length;
                                    if (_cardImageIndex < 0) {
                                      _cardImageIndex += property.images.length;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(AppIcons.chevronRight,
                                    color: AppColors.white, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      AppColors.black.withValues(alpha: 0.5),
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(28, 28),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _cardImageIndex =
                                        (_cardImageIndex + 1) % property.images.length;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.formattedPrice,
                            style: AppTextStyles.priceSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              property.title,
                              style: AppTextStyles.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.location,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(AppIcons.area,
                                  size: 14, color: AppColors.grey600),
                              const SizedBox(width: 2),
                              Text(
                                '${property.area.toStringAsFixed(0)}m²',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(AppIcons.rooms,
                                  size: 14, color: AppColors.grey600),
                              const SizedBox(width: 2),
                              Text(
                                '${property.rooms}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  'Dodane ${_formatListingDate(property.createdAt)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
