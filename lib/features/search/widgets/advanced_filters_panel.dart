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
                
                // Price filter (ceny komercyjne w milionach)
                FilterAccordion(
                  title: 'Cena (zł)',
                  icon: AppIcons.price,
                  child: PriceRangeSlider(
                    min: _filters.minPrice ?? 0,
                    max: _filters.maxPrice ?? 5000000,
                    minLimit: 0,
                    maxLimit: 50000000,
                    onChanged: (min, max) {
                      _updateFilters(_filters.copyWith(
                        minPrice: min,
                        maxPrice: max,
                      ));
                    },
                  ),
                ),
                
                // Powierzchnia (użytkowa + działka)
                FilterAccordion(
                  title: 'Powierzchnia (m²)',
                  icon: AppIcons.area,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Min. pow. użytkowa',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _updateFilters(_filters.copyWith(minArea: double.tryParse(v))),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max. pow. użytkowa',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _updateFilters(_filters.copyWith(maxArea: double.tryParse(v))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Min. pow. działki',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _updateFilters(_filters.copyWith(minPlotArea: double.tryParse(v))),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max. pow. działki',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _updateFilters(_filters.copyWith(maxPlotArea: double.tryParse(v))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Typ nieruchomości',
                        ),
                        value: _filters.propertyType,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Dowolny')),
                          DropdownMenuItem(value: 'office', child: Text('Budynki biurowe')),
                          DropdownMenuItem(value: 'warehouse', child: Text('Magazyny')),
                          DropdownMenuItem(value: 'retail', child: Text('Lokale handlowe')),
                          DropdownMenuItem(value: 'industrial', child: Text('Tereny / Hale przemysłowe')),
                          DropdownMenuItem(value: 'hotel', child: Text('Hotele i obiekty')),
                          DropdownMenuItem(value: 'land', child: Text('Działki inwestycyjne')),
                        ],
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(propertyType: value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status oferty',
                        ),
                        value: _filters.listingStatus,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wszystkie')),
                          DropdownMenuItem(value: 'for_sale', child: Text('Na sprzedaż')),
                          DropdownMenuItem(value: 'in_negotiation', child: Text('W negocjacji')),
                          DropdownMenuItem(value: 'sold', child: Text('Sprzedane')),
                        ],
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(listingStatus: value));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Wyposażenie (komercyjne)
                FilterAccordion(
                  title: 'Wyposażenie',
                  icon: AppIcons.parking,
                  child: Column(
                    children: [
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
                      CheckboxListTile(
                        title: const Text('Rampa / Doki załadunkowe'),
                        value: _filters.hasLoadingDock ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasLoadingDock: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Ochrona 24h'),
                        value: _filters.hasSecurity ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasSecurity: value));
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Recepcja'),
                        value: _filters.hasReception ?? false,
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(hasReception: value));
                        },
                      ),
                    ],
                  ),
                ),
                
                // Parametry specjalistyczne
                FilterAccordion(
                  title: 'Parametry techniczne',
                  icon: AppIcons.utilities,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Klasa budynku',
                        ),
                        value: _filters.buildingClass,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Dowolna')),
                          DropdownMenuItem(value: 'A+', child: Text('A+')),
                          DropdownMenuItem(value: 'A', child: Text('A')),
                          DropdownMenuItem(value: 'B+', child: Text('B+')),
                          DropdownMenuItem(value: 'B', child: Text('B')),
                          DropdownMenuItem(value: 'C', child: Text('C')),
                        ],
                        onChanged: (value) {
                          _updateFilters(_filters.copyWith(buildingClass: value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min. wysokość składowania (m)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          _updateFilters(_filters.copyWith(minCeilingHeight: double.tryParse(v)));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min. nośność posadzki (t/m²)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          _updateFilters(_filters.copyWith(minFloorLoadCapacity: double.tryParse(v)));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min. liczba miejsc parkingowych',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          _updateFilters(_filters.copyWith(minParkingSpaces: int.tryParse(v)));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min. moc przyłączeniowa (kW)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (v) {
                          _updateFilters(_filters.copyWith(minElectricalPower: double.tryParse(v)));
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
