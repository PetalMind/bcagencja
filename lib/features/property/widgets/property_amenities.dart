import 'package:flutter/material.dart';
import '../../../core/constants/listing_options.dart';
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

  static const Map<String, String> _categoryLabels = {
    'designation': 'Przeznaczenie',
    'additional': 'Informacje dodatkowe',
    'security': 'Bezpieczeństwo',
    'infrastructure': 'Infrastruktura',
    'office': 'Biuro i usługi',
    'terrain': 'Teren i dostęp',
    'other': 'Inne',
  };

  static String _categoryFor(String label) {
    const securityKeywords = ['Ochrona', 'Monitoring', 'Kontrola', 'alarm', 'p.poż'];
    const infraKeywords = ['Parking', 'Winda', 'Dok', 'Rampa', 'Suwnice', 'Plac', 'Waga', 'Transformatornia', 'Zaplecze', 'Toalety', 'Socjalne'];
    const officeKeywords = ['Recepcja', 'Wi-Fi', 'Sala konferencyjna', 'Restauracja', 'System rezerwacji', 'BMS', 'Klimatyzacja', 'Biura', 'Witryna', 'Wejście'];
    const terrainKeywords = ['Ogrodzona', 'Dojazd', 'Teren', 'MPZP', 'Media', 'KW', 'Bez obciążeń', 'Wszystkie zgody'];
    final l = label.toLowerCase();
    if (securityKeywords.any((k) => l.contains(k.toLowerCase()))) return 'security';
    if (infraKeywords.any((k) => l.contains(k.toLowerCase()))) return 'infrastructure';
    if (officeKeywords.any((k) => l.contains(k.toLowerCase()))) return 'office';
    if (terrainKeywords.any((k) => l.contains(k.toLowerCase()))) return 'terrain';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final features = <Map<String, dynamic>>[];

    // Add designation (Przeznaczenie lokalu)
    for (final key in property.designation) {
      features.add({
        'icon': Icons.storefront_rounded,
        'label': DesignationOptions.label(key),
        'category': 'designation',
      });
    }

    // Add additional info (klucze z AdditionalInfoOptions)
    for (final key in property.additionalInfo) {
      features.add({
        'icon': Icons.check_circle_outline_rounded,
        'label': AdditionalInfoOptions.label(key),
        'category': 'additional',
      });
    }

    // Add features from property.features list
    final featureIconMap = {
      'Recepcja 24h': AppIcons.reception,
      'Klimatyzacja': AppIcons.airConditioning,
      'BMS': AppIcons.bms,
      'Parking podziemny': AppIcons.parking,
      'Winda towarowa': AppIcons.elevator,
      'Ochrona': AppIcons.security,
      'Monitoring CCTV': AppIcons.monitoring,
      'Kontrola dostępu': AppIcons.accessControl,
      'Doki załadunkowe': AppIcons.loadingDock,
      'Rampy': AppIcons.loadingDock,
      'Suwnice': AppIcons.crane,
      'Posadzka przemysłowa': Icons.layers_rounded,
      'Ochrona 24h': AppIcons.security,
      'Plac manewrowy': Icons.local_shipping_rounded,
      'Parking TIR': AppIcons.parking,
      'System p.poż': AppIcons.fireSystem,
      'Duże witryny': Icons.window_rounded,
      'Wejście główne': Icons.door_sliding_rounded,
      'Witryna LED': Icons.lightbulb_rounded,
      'Zaplecze magazynowe': Icons.warehouse_rounded,
      'Toalety': Icons.wc_rounded,
      'System alarmowy': Icons.alarm_rounded,
      'Hala produkcyjna': Icons.factory_rounded,
      'Transformatornia': AppIcons.transformer,
      'Biura': Icons.business_rounded,
      'Socjalne': Icons.meeting_room_rounded,
      'Plac TIR': AppIcons.parking,
      'Waga samochodowa': Icons.scale_rounded,
      'Restauracja': Icons.restaurant_rounded,
      'Wi-Fi': Icons.wifi_rounded,
      'Sala konferencyjna': Icons.meeting_room_rounded,
      'System rezerwacji': Icons.calendar_today_rounded,
      'Media w granicy': AppIcons.utilities,
      'MPZP': Icons.map_rounded,
      'Ogrodzona': Icons.fence_rounded,
      'Dojazd asfaltowy': Icons.directions_car_rounded,
      'Teren równy': Icons.terrain_rounded,
      'KW': Icons.description_rounded,
      'Bez obciążeń': Icons.check_circle_rounded,
      'Wszystkie zgody': Icons.fact_check_rounded,
    };
    
    for (final feature in property.features) {
      features.add({
        'icon': featureIconMap[feature] ?? Icons.check_circle_rounded,
        'label': feature,
        'category': _categoryFor(feature),
      });
    }
    
    // Add boolean features
    if (property.hasLoadingDock) {
      features.add({'icon': AppIcons.loadingDock, 'label': 'Dok załadunkowy', 'category': 'infrastructure'});
    }
    if (property.hasParking) {
      features.add({'icon': AppIcons.parking, 'label': 'Parking', 'category': 'infrastructure'});
    }
    if (property.hasElevator) {
      features.add({'icon': AppIcons.elevator, 'label': 'Winda', 'category': 'infrastructure'});
    }
    if (property.hasSecurity) {
      features.add({'icon': AppIcons.security, 'label': 'Ochrona 24h', 'category': 'security'});
    }
    if (property.hasReception) {
      features.add({'icon': AppIcons.reception, 'label': 'Recepcja', 'category': 'office'});
    }
    
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final f in features) {
      final cat = f['category'] as String? ?? _categoryFor(f['label'] as String);
      grouped.putIfAbsent(cat, () => []).add(f);
    }
    final order = ['designation', 'additional', 'security', 'infrastructure', 'office', 'terrain', 'other'];
    final orderedCategories = order.where((c) => grouped.containsKey(c)).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : screenWidth < 900 ? 3 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wyposażenie i cechy',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final cat in orderedCategories) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              _categoryLabels[cat]!,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
            ),
            itemCount: grouped[cat]!.length,
            itemBuilder: (context, index) {
              final feature = grouped[cat]![index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      color: AppColors.accent,
                      size: AppSpacing.iconLg,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        feature['label'] as String,
                        style: AppTextStyles.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (cat != orderedCategories.last) const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
