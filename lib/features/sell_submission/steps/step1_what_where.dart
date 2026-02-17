import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 1: Co chcesz sprzedać (nieruchomość / grunt) + gdzie (miasto, województwo) + krótki opis.
class Step1WhatWhere extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;

  const Step1WhatWhere({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step1WhatWhere> createState() => _Step1WhatWhereState();
}

class _Step1WhatWhereState extends State<Step1WhatWhere> {
  late TextEditingController _cityController;
  late TextEditingController _voivodeshipController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.formData.city ?? '');
    _voivodeshipController =
        TextEditingController(text: widget.formData.voivodeship ?? '');
    _descriptionController =
        TextEditingController(text: widget.formData.description ?? '');
  }

  @override
  void dispose() {
    _cityController.dispose();
    _voivodeshipController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.city = _cityController.text;
    widget.formData.voivodeship = _voivodeshipController.text;
    widget.formData.description = _descriptionController.text;
    widget.onDataChanged(widget.formData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Co chcesz sprzedać?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Wybierz typ – pomoże nam dopasować dalsze kroki.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  'Nieruchomość',
                  'property',
                  Icons.business_rounded,
                  widget.formData.assetType == 'property',
                  () {
                    widget.formData.assetType = 'property';
                    widget.onDataChanged(widget.formData);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTypeChip(
                  'Grunt',
                  'land',
                  Icons.landscape_rounded,
                  widget.formData.assetType == 'land',
                  () {
                    widget.formData.assetType = 'land';
                    widget.onDataChanged(widget.formData);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Gdzie znajduje się obiekt?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _cityController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Miasto *',
              hintText: 'np. Warszawa, Kraków',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _voivodeshipController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Województwo (opcjonalnie)',
              hintText: 'np. mazowieckie',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Krótki opis (opcjonalnie)',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Np. powierzchnia, stan, cel sprzedaży – skontaktujemy się po szczegóły.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descriptionController,
            onChanged: (_) => _syncToFormData(),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Opisz w kilku zdaniach...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
