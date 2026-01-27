import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';

class SimilarListings extends StatelessWidget {
  final String propertyId;
  
  const SimilarListings({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    // Mock similar properties
    final similarProperties = List.generate(4, (i) => Property.mock(i + 10));
    
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
        
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : 0,
            ),
            itemCount: similarProperties.length,
            itemBuilder: (context, index) {
              final property = similarProperties[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: _buildSimilarCard(context, property),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSimilarCard(BuildContext context, Property property) {
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
                    child: Image.network(
                      property.mainImage ?? property.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        AppIcons.image,
                        size: 48,
                        color: AppColors.grey400,
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
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.formattedPrice,
                    style: AppTextStyles.priceMedium,
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
