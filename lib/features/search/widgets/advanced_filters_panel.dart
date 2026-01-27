import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/search_filters_model.dart';
import 'filter_accordion.dart';
import 'price_range_slider.dart';

class AdvancedFiltersPanel extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onFiltersChanged;
  
  const AdvancedFiltersPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFiltersPanel> createState() => _AdvancedFiltersPanelState();
}

class _AdvancedFiltersPanelState extends State<AdvancedFiltersPanel> {
  late SearchFilters _filters;
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }
  
  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtry', style: AppTextStyles.titleLarge),
                if (_filters.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      _updateFilters(SearchFilters());
                    },
                    child: const Text('Wyczyść'),
                  ),
              ],
            ),
          ),
          const Divider(),
          
          // Filters
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Location filter
                FilterAccordion(
                  title: 'Lokalizacja',
                  icon: AppIcons.location,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Miasto, dzielnica...',
                          prefixIcon: Icon(AppIcons.search),
                        ),
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(location: value));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Price filter
                FilterAccordion(
                  title: 'Cena',
                  icon: Icons.monetization_on_rounded,
                  child: PriceRangeSlider(
                    min: _filters.minPrice ?? 0,
                    max: _filters.maxPrice ?? 2000000,
                    onChanged: (min, max) {
                      _updateFilters(_filters.copyWith(
                        minPrice: min,
                        maxPrice: max,
                      ));
                    },
                  ),
                ),
                
                // Basic parameters
                FilterAccordion(
                  title: 'Parametry podstawowe',
                  icon: AppIcons.apartment,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Min. powierzchnia',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max. powierzchnia',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Liczba pokoi',
                        ),
                        items: List.generate(10, (i) => i + 1).map((rooms) {
                          return DropdownMenuItem(
                            value: rooms,
                            child: Text('$rooms pokoi'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(minRooms: value));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Amenities
                FilterAccordion(
                  title: 'Wyposażenie',
                  icon: Icons.checkroom_rounded,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Balkon'),
                        value: _filters.hasBalcony ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasBalcony: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Parking'),
                        value: _filters.hasParking ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasParking: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Winda'),
                        value: _filters.hasElevator ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasElevator: value));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Preferences
                FilterAccordion(
                  title: 'Preferencje',
                  icon: AppIcons.settings,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Tylko ze zdjęciami'),
                        value: _filters.onlyWithPhotos,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(onlyWithPhotos: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Od właściciela'),
                        value: _filters.fromOwner,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(fromOwner: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Wirtualny spacer'),
                        value: _filters.withVirtualTour,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(withVirtualTour: value));
                        },
                      ),
                    ],
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
