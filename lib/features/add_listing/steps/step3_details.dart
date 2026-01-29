import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step3Details extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;

  const Step3Details({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step3Details> createState() => _Step3DetailsState();
}

class _Step3DetailsState extends State<Step3Details> {
  late TextEditingController _descriptionController;

  static const _amenityOptions = [
    ('Parking', 'parking'),
    ('Windy', 'elevator'),
    ('Klimatyzacja', 'airConditioning'),
    ('Monitoring', 'monitoring'),
    ('Recepcja', 'reception'),
    ('Dostęp 24h', 'access24'),
  ];

  static const _heatingOptions = [
    'Miejskie',
    'Gazowe',
    'Elektryczne',
    'Pompa ciepła',
    'Kotłownia',
    'Inne',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.formData.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncDescription() {
    widget.formData.description = _descriptionController.text;
    widget.onDataChanged(widget.formData);
  }

  void _toggleAmenity(String value) {
    setState(() {
      if (widget.formData.amenities.contains(value)) {
        widget.formData.amenities.remove(value);
      } else {
        widget.formData.amenities.add(value);
      }
      widget.onDataChanged(widget.formData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final descLength = _descriptionController.text.length;
    final descValid = descLength >= 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Opis', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Opis musi mieć minimum 50 znaków.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Opis nieruchomości *',
              hintText: 'Opisz lokalizację, stan, zalety obiektu...',
              alignLabelWithHint: true,
              errorText: descLength > 0 && !descValid
                  ? 'Wpisz min. 50 znaków (${50 - descLength} pozostało)'
                  : null,
              counterText: '$descLength / 50 znaków',
            ),
            maxLines: 6,
            onChanged: (_) {
              _syncDescription();
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Udogodnienia', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _amenityOptions.map((option) {
              final (label, value) = option;
              final isSelected = widget.formData.amenities.contains(value);
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => _toggleAmenity(value),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Ogrzewanie (opcjonalnie)', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: widget.formData.heating,
            decoration: const InputDecoration(
              labelText: 'Typ ogrzewania',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nie wybrano')),
              ..._heatingOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))),
            ],
            onChanged: (v) {
              widget.formData.heating = v;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
