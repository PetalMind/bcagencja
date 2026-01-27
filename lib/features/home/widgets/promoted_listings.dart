import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/router/app_router.dart';

class PromotedListings extends StatelessWidget {
  const PromotedListings({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    // Mock promoted properties
    final promotedProperties = List.generate(3, (i) => Property.mock(i));
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.containerMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Promowane oferty',
                    style: isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRouter.searchResults),
                    child: const Text('Zobacz wszystkie'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: promotedProperties.map((property) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _buildPromotedCard(context, property),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: promotedProperties.map((property) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildPromotedCard(context, property),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromotedCard(BuildContext context, Property property) {
    return GestureDetector(
      onTap: () => context.go('/property/${property.id}'),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd),
                    ),
                    color: AppColors.grey200,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd),
                    ),
                    child: Image.network(
                      property.mainImage ?? property.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.grey200,
                        child: const Icon(
                          AppIcons.image,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Promoted badge
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'PROMOWANE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Favorite button
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    icon: const Icon(AppIcons.favoriteBorder),
                    color: AppColors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.black.withOpacity(0.5),
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
                  // Price
                  Text(
                    property.formattedPrice,
                    style: AppTextStyles.priceMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Title
                  Text(
                    property.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        AppIcons.location,
                        size: AppSpacing.iconSm,
                        color: AppColors.grey600,
                      ),
                      const SizedBox(width: AppSpacing.xs),
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
                  
                  // Parameters
                  Row(
                    children: [
                      _buildParameter(
                        icon: AppIcons.area,
                        value: '${property.area.toStringAsFixed(0)} m²',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildParameter(
                        icon: AppIcons.rooms,
                        value: '${property.rooms} pok.',
                      ),
                      if (property.floor != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        _buildParameter(
                          icon: AppIcons.floor,
                          value: '${property.floor} p.',
                        ),
                      ],
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
  
  Widget _buildParameter({
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSm,
          color: AppColors.grey600,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
