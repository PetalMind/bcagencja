import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/property_model.dart';

/// Modal porównania 2–5 ofert: tabela parametrów (Cena, ROI, Powierzchnia, itd.).
void showCompareOffersModal({
  required BuildContext context,
  required List<Property> properties,
}) {
  if (properties.length < 2 || properties.length > 5) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CompareOffersSheet(properties: properties),
  );
}

class _CompareOffersSheet extends StatelessWidget {
  const _CompareOffersSheet({required this.properties});

  final List<Property> properties;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final rows = _buildRows();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(AppIcons.statistics, color: AppColors.accent, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Porównaj (${properties.length} oferty)',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isMobile
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      ...rows.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.label,
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    ...r.values.asMap().entries.map((e) => Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                child: Text(
                                                  properties[e.key].title.length > 15
                                                      ? 'O${e.key + 1}'
                                                      : properties[e.key].title.substring(0, properties[e.key].title.length.clamp(0, 12)),
                                                  style: AppTextStyles.labelSmall,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium)),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.grey50),
                      columns: [
                        const DataColumn(label: Text('Parametr')),
                        ...properties.map((p) => DataColumn(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  p.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),
                            )),
                      ],
                      rows: rows.map((r) => DataRow(
                            cells: [
                              DataCell(Text(r.label, style: AppTextStyles.labelMedium)),
                              ...r.values.map((v) => DataCell(Text(v, style: AppTextStyles.bodyMedium))),
                            ],
                          )).toList(),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Eksport do Excel
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Eksport do Excel – wkrótce'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(AppIcons.download, size: 20),
                  label: const Text('Eksportuj do Excel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Zamknij'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<({String label, List<String> values})> _buildRows() {
    return [
      (label: 'Cena', values: properties.map((p) => p.formattedPrice).toList()),
      (label: 'ROI', values: properties.map((p) => p.roi != null ? '${p.roi!.toStringAsFixed(1)}%' : '–').toList()),
      (label: 'Powierzchnia', values: properties.map((p) => '${p.area.toStringAsFixed(0)} m²').toList()),
      (label: 'Typ', values: properties.map((p) => p.propertyTypeLabel).toList()),
      (label: 'Lokalizacja', values: properties.map((p) => p.city).toList()),
      (label: 'Cena/m²', values: properties.map((p) => p.pricePerSqm != null ? '${p.pricePerSqm!.toStringAsFixed(0)} zł/m²' : '–').toList()),
    ];
  }
}
