import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step5Contact extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;

  const Step5Contact({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step5Contact> createState() => _Step5ContactState();
}

class _Step5ContactState extends State<Step5Contact> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  static const _contactTimeOptions = [
    'Rano (8–12)',
    'Południe (12–17)',
    'Wieczór (17–21)',
    'Dowolna pora',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.formData.contactName ?? '');
    _phoneController = TextEditingController(text: widget.formData.contactPhone ?? '');
    _emailController = TextEditingController(text: widget.formData.contactEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.contactName = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    widget.formData.contactPhone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    widget.formData.contactEmail = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    widget.onDataChanged(widget.formData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dane kontaktowe', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pola wymagane: Imię i nazwisko, Telefon, E-mail.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Imię i nazwisko *',
              prefixIcon: Icon(Icons.person_rounded),
              hintText: 'np. Jan Kowalski',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon *',
              prefixIcon: Icon(AppIcons.phone),
              hintText: 'np. +48 123 456 789',
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-mail *',
              prefixIcon: Icon(AppIcons.email),
              hintText: 'np. jan@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Preferowany czas kontaktu (opcjonalnie)', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: widget.formData.preferredContactTime,
            decoration: const InputDecoration(
              labelText: 'Kiedy można się skontaktować',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nie wybrano')),
              ..._contactTimeOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))),
            ],
            onChanged: (v) {
              widget.formData.preferredContactTime = v;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
