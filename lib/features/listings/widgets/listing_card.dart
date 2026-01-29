import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../property/widgets/property_gallery.dart';

class ListingCard extends StatefulWidget {
  final Property property;

  const ListingCard({
    super.key,
    required this.property,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _isHovered = false;
  int _cardImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: InkWell(
          onTap: () => context.go('/property/${widget.property.id}'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Image (30% width) – tap otwiera lightbox, hover – mini-galeria
                GestureDetector(
                  onTap: () {
                    if (widget.property.images.isEmpty) return;
                    showGalleryLightbox(
                      context,
                      images: widget.property.images,
                      initialIndex: _cardImageIndex.clamp(0, widget.property.images.length - 1),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppSpacing.radiusMd),
                    ),
                    child: Container(
                      width: 150,
                      height: 180,
                      color: AppColors.grey200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCardImage(),
                          if (widget.property.promoted)
                      Positioned(
                        top: AppSpacing.xs,
                        left: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            'PROMOWANE',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    if (widget.property.images.length > 1)
                      Positioned(
                        bottom: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.image,
                                size: 14,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${widget.property.images.length}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: IconButton(
                        icon: const Icon(AppIcons.favoriteBorder, size: 20),
                        color: AppColors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.black.withValues(alpha: 0.5),
                          padding: const EdgeInsets.all(AppSpacing.xs),
                        ),
                        onPressed: () {},
                      ),
                    ),
                          if (_isHovered && widget.property.images.length > 1) ...[
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(AppIcons.chevronLeft, color: AppColors.white, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.black.withValues(alpha: 0.5),
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cardImageIndex = (_cardImageIndex - 1) % widget.property.images.length;
                                      if (_cardImageIndex < 0) _cardImageIndex += widget.property.images.length;
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
                                  icon: const Icon(AppIcons.chevronRight, color: AppColors.white, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.black.withValues(alpha: 0.5),
                                    padding: const EdgeInsets.all(AppSpacing.xs),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _cardImageIndex = (_cardImageIndex + 1) % widget.property.images.length;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            
            // Content (70% width)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      widget.property.formattedPrice,
                      style: AppTextStyles.priceMedium,
                    ),
                    if (widget.property.pricePerSqm != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.property.pricePerSqm!.toStringAsFixed(0)} zł/m²',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Title
                    Text(
                      widget.property.title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(AppIcons.location, size: 16, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.property.location,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Description
                    Text(
                      widget.property.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Parameters
                    Row(
                      children: [
                        _buildParam(AppIcons.area, '${widget.property.area.toStringAsFixed(0)} m²'),
                        const SizedBox(width: AppSpacing.md),
                        _buildParam(AppIcons.rooms, '${widget.property.rooms} pok.'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Amenities icons
                    Row(
                      children: [
                        if (widget.property.hasParking) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(AppIcons.parking, size: 16, color: AppColors.grey600),
                        ],
                        if (widget.property.hasElevator) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(AppIcons.elevator, size: 16, color: AppColors.grey600),
                        ],
                        const Spacer(),
                        Text(
                          _formatListingDate(widget.property.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    
                    // Contact button
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => context.go('/property/${widget.property.id}'),
                      child: const Text('Kontakt'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCardImage() {
    final images = widget.property.images;
    if (images.isEmpty) {
      return const Center(
        child: Icon(AppIcons.image, size: 48, color: AppColors.grey400),
      );
    }
    final index = _cardImageIndex.clamp(0, images.length - 1);
    final url = images.length > 1 ? images[index] : (widget.property.mainImage ?? images[0]);
    return CachedNetworkImage(
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
        size: 48,
        color: AppColors.grey400,
      ),
    );
  }

  String _formatListingDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    final days = diff.inDays.abs();
    if (days == 0) return 'Dzisiaj';
    if (days == 1) return 'Wczoraj';
    if (days < 7) return '$days dni temu';
    if (days < 30) return '${(days / 7).floor()} tyg. temu';
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildParam(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
