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
    final basicItems = <_ParamItem>[
      _ParamItem('Typ nieruchomości', property.propertyTypeLabel),
      _ParamItem('Powierzchnia użytkowa', '${property.area.toStringAsFixed(0)} m²'),
      if (property.pricePerSqm != null)
        _ParamItem('Cena za m²', '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²'),
      if (property.floors > 0)
        _ParamItem('Liczba kondygnacji', '${property.floors}'),
      if (property.parkingSpaces != null)
        _ParamItem('Miejsca parkingowe', '${property.parkingSpaces}'),
      if (property.ceilingHeight != null)
        _ParamItem('Wysokość użytkowa', '${property.ceilingHeight!.toStringAsFixed(1)} m'),
      if (property.plotArea != null && property.plotArea! > 0)
        _ParamItem('Powierzchnia działki', '${property.plotArea!.toStringAsFixed(0)} m²'),
      if (property.yearBuilt != null)
        _ParamItem('Rok budowy', '${property.yearBuilt}'),
      if (property.condition != null)
        _ParamItem('Stan techniczny', property.conditionLabel),
      if (property.buildingClass != null)
        _ParamItem('Klasa budynku', property.buildingClassLabel),
      if (property.zoning != null)
        _ParamItem('Przeznaczenie (MPZP)', property.zoning!),
    ];

    final financialItems = <_ParamItem>[
      if (property.roi != null)
        _ParamItem('Prognozowany ROI', '${property.roi!.toStringAsFixed(1)}%'),
      if (property.currentRent != null)
        _ParamItem('Obecny czynsz', '${property.currentRent!.toStringAsFixed(0)} zł/mc'),
      if (property.tenant != null)
        _ParamItem('Najemca', property.tenant!),
      if (property.leaseUntil != null)
        _ParamItem(
          'Umowa do',
          '${property.leaseUntil!.day}.${property.leaseUntil!.month}.${property.leaseUntil!.year}',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parametry techniczne',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (basicItems.isNotEmpty) ...[
          _buildSection('Podstawowe', basicItems),
          if (financialItems.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        ],
        if (financialItems.isNotEmpty) _buildSection('Finansowe i najem', financialItems),
      ],
    );
  }

  Widget _buildSection(String title, List<_ParamItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _buildRow(
                  items[i].label,
                  items[i].value,
                  isLast: i == items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
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

class _ParamItem {
  final String label;
  final String value;
  _ParamItem(this.label, this.value);
}
