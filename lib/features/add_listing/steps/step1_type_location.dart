import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step1TypeLocation extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;
  /// Błędy walidacji z rodzica (ustawiane gdy użytkownik naciska "Dalej" przy niewypełnionych polach).
  final Map<String, String?>? validationErrors;

  const Step1TypeLocation({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.validationErrors,
  });

  @override
  State<Step1TypeLocation> createState() => _Step1TypeLocationState();
}

class _Step1TypeLocationState extends State<Step1TypeLocation> {
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.formData.city ?? '');
    _districtController = TextEditingController(text: widget.formData.district ?? '');
    _streetController = TextEditingController(text: widget.formData.street ?? '');
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.city = _cityController.text;
    widget.formData.district = _districtController.text;
    widget.formData.street = _streetController.text;
    widget.onDataChanged(widget.formData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sekcja: Typ transakcji (wymagane)
          Semantics(
            label: 'Typ transakcji, wymagane',
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Typ transakcji', style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            'Sprzedaż',
                            'sale',
                            widget.formData.transactionType == 'sale',
                            () {
                              widget.formData.transactionType = 'sale';
                              widget.onDataChanged(widget.formData);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildTypeButton(
                            'Wynajem',
                            'rent',
                            widget.formData.transactionType == 'rent',
                            () {
                              widget.formData.transactionType = 'rent';
                              widget.onDataChanged(widget.formData);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sekcja: Typ nieruchomości (wymagane)
          Semantics(
            label: 'Typ nieruchomości, wybierz jeden typ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Typ nieruchomości', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (widget.validationErrors?['propertyType'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      widget.validationErrors!['propertyType']!,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.0,
                  children: [
                    _buildPropertyTypeCard('Biurowiec', 'office', AppIcons.office),
                    _buildPropertyTypeCard('Magazyn', 'warehouse', AppIcons.warehouse),
                    _buildPropertyTypeCard('Handlowy', 'retail', AppIcons.retail),
                    _buildPropertyTypeCard('Przemysłowy', 'industrial', AppIcons.industrial),
                    _buildPropertyTypeCard('Hotel', 'hotel', AppIcons.hotel),
                    _buildPropertyTypeCard('Działka', 'land', AppIcons.land),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Wybierz jeden typ',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sekcja: Lokalizacja
          Text('Lokalizacja', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pola opcjonalne: Dzielnica / Osiedle, Ulica',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Miasto (wymagane)',
              prefixIcon: const Icon(AppIcons.location),
              errorText: widget.validationErrors?['city'],
            ),
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'Dzielnica / Osiedle (opcjonalnie)',
            ),
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Ulica (opcjonalnie)',
            ),
            onChanged: (_) => _syncToFormData(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, bool isSelected, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.accent : AppColors.grey200,
        foregroundColor: isSelected ? AppColors.white : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: Text(label),
    );
  }

  Widget _buildPropertyTypeCard(String label, String value, IconData icon) {
    final isSelected = widget.formData.propertyType == value;

    return Semantics(
      label: '$label, przycisk${isSelected ? ', wybrany' : ''}',
      button: true,
      child: Card(
        elevation: isSelected ? 4 : 1,
        child: InkWell(
          onTap: () {
            widget.formData.propertyType = value;
            widget.onDataChanged(widget.formData);
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? AppColors.accent : AppColors.grey600,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
