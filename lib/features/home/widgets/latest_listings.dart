import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';

class LatestListings extends StatelessWidget {
  const LatestListings({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint &&
        screenWidth < AppSpacing.tabletBreakpoint;
    
    // Mock latest properties
    final latestProperties = List.generate(8, (i) => Property.mock(i + 3));
    
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    
    return Container(
      width: double.infinity,
      color: AppColors.backgroundGrey,
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
              Text(
                'Najnowsze ogłoszenia',
                style: isMobile
                    ? AppTextStyles.headlineMedium
                    : AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.75,
                ),
                itemCount: latestProperties.length,
                itemBuilder: (context, index) {
                  return _buildListingCard(context, latestProperties[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildListingCard(BuildContext context, Property property) {
    return GestureDetector(
      onTap: () => context.go('/property/${property.id}'),
      child: Card(
        elevation: 2,
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
                  height: 150,
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
                          size: 32,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Favorite button
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: IconButton(
                    icon: const Icon(AppIcons.favoriteBorder, size: 20),
                    color: AppColors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      property.formattedPrice,
                      style: AppTextStyles.priceSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Title
                    Text(
                      property.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Parameters
                    Row(
                      children: [
                        Icon(
                          AppIcons.area,
                          size: AppSpacing.iconXs,
                          color: AppColors.grey600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${property.area.toStringAsFixed(0)}m²',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          AppIcons.rooms,
                          size: AppSpacing.iconXs,
                          color: AppColors.grey600,
                        ),
                        const SizedBox(width: 2),
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
            ),
          ],
        ),
      ),
    );
  }
}
