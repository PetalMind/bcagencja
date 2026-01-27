import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';

class ListingCard extends StatelessWidget {
  final Property property;
  
  const ListingCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: () => context.go('/property/${property.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (30% width)
            ClipRRect(
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
                    Image.network(
                      property.mainImage ?? property.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        AppIcons.image,
                        size: 48,
                        color: AppColors.grey400,
                      ),
                    ),
                    if (property.promoted)
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
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: IconButton(
                        icon: const Icon(AppIcons.favoriteBorder, size: 20),
                        color: AppColors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(AppSpacing.xs),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
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
                      property.formattedPrice,
                      style: AppTextStyles.priceMedium,
                    ),
                    if (property.pricePerSqm != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Title
                    Text(
                      property.title,
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
                            property.location,
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
                      property.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Parameters
                    Row(
                      children: [
                        _buildParam(AppIcons.area, '${property.area.toStringAsFixed(0)} m²'),
                        const SizedBox(width: AppSpacing.md),
                        _buildParam(AppIcons.rooms, '${property.rooms} pok.'),
                        if (property.floor != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          _buildParam(AppIcons.floor, '${property.floor} p.'),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Amenities icons
                    Row(
                      children: [
                        if (property.hasBalcony)
                          const Icon(AppIcons.balcony, size: 16, color: AppColors.grey600),
                        if (property.hasParking) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(AppIcons.parking, size: 16, color: AppColors.grey600),
                        ],
                        if (property.hasElevator) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(AppIcons.elevator, size: 16, color: AppColors.grey600),
                        ],
                        const Spacer(),
                        Text(
                          property.createdAt.difference(DateTime.now()).inDays.abs() == 0
                              ? 'Dzisiaj'
                              : '${property.createdAt.difference(DateTime.now()).inDays.abs()} dni temu',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    
                    // Contact button
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => context.go('/property/${property.id}'),
                      child: const Text('Kontakt'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
