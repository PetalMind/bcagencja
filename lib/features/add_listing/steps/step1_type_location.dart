import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step1TypeLocation extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;
  
  const Step1TypeLocation({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step1TypeLocation> createState() => _Step1TypeLocationState();
}

class _Step1TypeLocationState extends State<Step1TypeLocation> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          
          const SizedBox(height: AppSpacing.xl),
          Text('Typ nieruchomości', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _buildPropertyTypeCard(
                'Mieszkanie',
                'apartment',
                AppIcons.apartment,
              ),
              _buildPropertyTypeCard(
                'Dom',
                'house',
                AppIcons.house,
              ),
              _buildPropertyTypeCard(
                'Działka',
                'land',
                AppIcons.land,
              ),
              _buildPropertyTypeCard(
                'Lokal użytkowy',
                'commercial',
                AppIcons.commercial,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          Text('Lokalizacja', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Miasto',
              prefixIcon: Icon(AppIcons.location),
            ),
            onChanged: (value) {
              widget.formData.city = value;
              widget.onDataChanged(widget.formData);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Dzielnica / Osiedle',
            ),
            onChanged: (value) {
              widget.formData.district = value;
              widget.onDataChanged(widget.formData);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Ulica (opcjonalnie)',
            ),
            onChanged: (value) {
              widget.formData.street = value;
              widget.onDataChanged(widget.formData);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeButton(String label, String value, bool isSelected, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? null : Colors.grey[200],
        foregroundColor: isSelected ? null : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: Text(label),
    );
  }
  
  Widget _buildPropertyTypeCard(String label, String value, IconData icon) {
    final isSelected = widget.formData.propertyType == value;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          widget.formData.propertyType = value;
          widget.onDataChanged(widget.formData);
          setState(() {});
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: isSelected ? Colors.orange : Colors.grey),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
