import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';

class PropertyAmenities extends StatelessWidget {
  final Property property;
  
  const PropertyAmenities({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = <Map<String, dynamic>>[];
    
    if (property.hasBalcony) {
      amenities.add({'icon': AppIcons.balcony, 'label': 'Balkon'});
    }
    if (property.hasParking) {
      amenities.add({'icon': AppIcons.parking, 'label': 'Parking'});
    }
    if (property.hasElevator) {
      amenities.add({'icon': AppIcons.elevator, 'label': 'Winda'});
    }
    if (property.hasGarden) {
      amenities.add({'icon': AppIcons.garden, 'label': 'Ogród'});
    }
    
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wyposażenie',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: amenities.length,
          itemBuilder: (context, index) {
            final amenity = amenities[index];
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    amenity['icon'] as IconData,
                    color: AppColors.accent,
                    size: AppSpacing.iconLg,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    amenity['label'] as String,
                    style: AppTextStyles.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
