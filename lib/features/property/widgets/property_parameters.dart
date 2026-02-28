import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
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
      _ParamItem(Icons.category_rounded, 'Typ nieruchomości', property.propertyTypeLabel),
      _ParamItem(AppIcons.area, 'Powierzchnia użytkowa', '${property.area.toStringAsFixed(0)} m²'),
      if (property.pricePerSqm != null)
        _ParamItem(AppIcons.price, 'Cena za m²', '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²'),
      if (property.yearBuilt != null || property.yearModernized != null)
        _ParamItem(
          AppIcons.calendar,
          'Rok budowy / modernizacji',
          [
            if (property.yearBuilt != null) property.yearBuilt.toString(),
            if (property.yearModernized != null) property.yearModernized.toString(),
          ].join(' / '),
        ),
      if (property.floors > 0)
        _ParamItem(AppIcons.floors, 'Liczba kondygnacji', '${property.floors}'),
      if (property.parkingSpaces != null && property.parkingSpaces! > 0)
        _ParamItem(AppIcons.parkingSpaces, 'Liczba miejsc parkingowych', '${property.parkingSpaces}'),
      if (property.ceilingHeight != null)
        _ParamItem(AppIcons.ceilingHeight, 'Wysokość użytkowa', '${property.ceilingHeight!.toStringAsFixed(1)} m'),
      if (property.plotArea != null && property.plotArea! > 0)
        _ParamItem(AppIcons.plotArea, 'Powierzchnia działki', '${property.plotArea!.toStringAsFixed(0)} m²'),
      if (_mediaDisplay != null)
        _ParamItem(AppIcons.transformer, 'Media', _mediaDisplay!),
      if (property.zoning != null)
        _ParamItem(Icons.map_rounded, 'Przeznaczenie / MPZP / WZ', property.zoning!),
      if (property.expandable == true)
        _ParamItem(Icons.expand_more_rounded, 'Możliwość rozbudowy', 'Tak'),
      if (property.condition != null)
        _ParamItem(Icons.build_rounded, 'Stan techniczny', property.conditionLabel),
      if (property.buildingClass != null)
        _ParamItem(Icons.grade_rounded, 'Klasa budynku', property.buildingClassLabel),
    ];

    final financialItems = <_ParamItem>[
      if (property.roi != null)
        _ParamItem(AppIcons.trending, 'Prognozowany ROI', '${property.roi!.toStringAsFixed(1)}%'),
      if (property.currentRent != null)
        _ParamItem(AppIcons.price, 'Obecny czynsz', '${property.currentRent!.toStringAsFixed(0)} zł/mc'),
      if (property.tenant != null)
        _ParamItem(Icons.storefront_rounded, 'Najemca', property.tenant!),
      if (property.leaseUntil != null)
        _ParamItem(
          AppIcons.calendar,
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

  String? get _mediaDisplay {
    final parts = <String>[];
    if (property.electricalPower != null && property.electricalPower! > 0) {
      parts.add('Moc przyłącza: ${property.electricalPower!.toStringAsFixed(0)} kW');
    }
    if (property.heatingType != null && property.heatingType!.isNotEmpty) {
      parts.add('Ogrzewanie: ${property.heatingType}');
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
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
                  items[i].icon,
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

  Widget _buildRow(IconData icon, String label, String value, {bool isLast = false}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

class _ParamItem {
  final IconData icon;
  final String label;
  final String value;
  _ParamItem(this.icon, this.label, this.value);
}
