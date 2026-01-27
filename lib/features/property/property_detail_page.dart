import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/property/mobile_contact_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/property_model.dart';
import 'widgets/property_gallery.dart';
import 'widgets/property_info_panel.dart';
import 'widgets/property_description.dart';
import 'widgets/property_parameters.dart';
import 'widgets/property_amenities.dart';
import 'widgets/similar_listings.dart';

class PropertyDetailPage extends StatelessWidget {
  final String propertyId;
  
  const PropertyDetailPage({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint &&
        screenWidth < AppSpacing.tabletBreakpoint;
    
    // Get property data - in real app this would come from API/state management
    final property = _getPropertyById(propertyId);
    
    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main content
            Container(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMaxWidth,
              ),
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 0 : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs
                  if (!isMobile) _buildBreadcrumbs(property),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title and location
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.title,
                                style: isMobile
                                    ? AppTextStyles.headlineSmall
                                    : AppTextStyles.headlineLarge,
                              ),
                            ),
                            if (property.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      AppIcons.verified,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Zweryfikowane',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              AppIcons.location,
                              size: 20,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                property.location,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              AppIcons.visibility,
                              size: 16,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${property.views} wyświetleń',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              AppIcons.favorites,
                              size: 16,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${property.favorites} polubień',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Dodano: ${_formatDate(property.createdAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Gallery and info panel
                  if (isMobile || isTablet)
                    _buildMobileLayout(property)
                  else
                    _buildDesktopLayout(property),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyDescription(
                      title: 'Opis',
                      description: property.description,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Parameters
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyParameters(property: property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Amenities
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyAmenities(property: property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Location
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: _buildLocationSection(property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Similar listings
                  SimilarListings(propertyId: propertyId),
                  
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? MobileContactBar(
              price: property.formattedPrice,
              phone: property.ownerPhone,
              onMessageTap: () {
                // Show contact form
              },
            )
          : null,
    );
  }
  
  Widget _buildBreadcrumbs(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Text(
            'Strona główna',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          Text(
            'Wyszukiwanie',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          Text(
            property.city,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          Expanded(
            child: Text(
              property.propertyTypeLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gallery (left side, 60%)
          Expanded(
            flex: 6,
            child: PropertyGallery(images: property.images),
          ),
          
          const SizedBox(width: AppSpacing.xl),
          
          // Info panel (right side, 40%)
          SizedBox(
            width: 400,
            child: PropertyInfoPanel(property: property),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          PropertyGallery(images: property.images),
          const SizedBox(height: AppSpacing.xl),
          PropertyInfoPanel(property: property),
        ],
      ),
    );
  }
  
  Widget _buildLocationSection(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokalizacja',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Map placeholder
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.map,
                      size: 48,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mapa Google Maps',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${property.city}, ${property.district}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Location details
        Text(
          'O okolicy',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nieruchomość znajduje się w doskonałej lokalizacji w ${property.district}, w pobliżu centrum ${property.city}. W okolicy znajdują się liczne sklepy, restauracje, szkoły oraz doskonale rozwinięta komunikacja miejska.',
          style: AppTextStyles.bodyMedium,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Nearby points
        Text(
          'W pobliżu',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildNearbyPoint('Metro / Przystanek', '300 m', AppIcons.directions),
        _buildNearbyPoint('Szkoła podstawowa', '500 m', Icons.school_rounded),
        _buildNearbyPoint('Centrum handlowe', '1 km', Icons.shopping_cart_rounded),
        _buildNearbyPoint('Park', '400 m', AppIcons.garden),
      ],
    );
  }
  
  Widget _buildNearbyPoint(String name, String distance, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(name, style: AppTextStyles.bodyMedium),
          ),
          Text(
            distance,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Dzisiaj';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tyg. temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
  
  Property _getPropertyById(String id) {
    // Extract number from id (e.g., "property_2" -> 2)
    final index = int.tryParse(id.replaceAll('property_', '')) ?? 0;
    return Property.mock(index);
  }
}
