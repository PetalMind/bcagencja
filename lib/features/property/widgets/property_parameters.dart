import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/state/models/property_model.dart';

class PropertyParameters extends StatelessWidget {
  final Property property;
  
  const PropertyParameters({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parametry techniczne',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              _buildRow('Powierzchnia', '${property.area.toStringAsFixed(0)} m²'),
              _buildRow('Liczba pokoi', '${property.rooms}'),
              if (property.floor != null)
                _buildRow('Piętro', '${property.floor}'),
              if (property.yearBuilt != null)
                _buildRow('Rok budowy', '${property.yearBuilt}'),
              if (property.condition != null)
                _buildRow('Stan', property.condition!),
              if (property.heating != null)
                _buildRow('Ogrzewanie', property.heating!),
              _buildRow('Typ transakcji', property.transactionTypeLabel),
              _buildRow('Typ nieruchomości', property.propertyTypeLabel),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
