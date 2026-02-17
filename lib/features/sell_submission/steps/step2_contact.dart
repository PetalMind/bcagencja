import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 2: Dane kontaktowe – imię, email, telefon, preferowana godzina kontaktu.
class Step2Contact extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;

  const Step2Contact({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step2Contact> createState() => _Step2ContactState();
}

class _Step2ContactState extends State<Step2Contact> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _preferredTimeController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.formData.contactName ?? '');
    _emailController =
        TextEditingController(text: widget.formData.contactEmail ?? '');
    _phoneController =
        TextEditingController(text: widget.formData.contactPhone ?? '');
    _preferredTimeController = TextEditingController(
        text: widget.formData.preferredContactTime ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _preferredTimeController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.contactName = _nameController.text;
    widget.formData.contactEmail = _emailController.text;
    widget.formData.contactPhone = _phoneController.text;
    widget.formData.preferredContactTime = _preferredTimeController.text;
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
            'Jak się z Tobą skontaktować?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Skontaktujemy się w ciągu 1–2 dni roboczych i zaproponujemy dalsze kroki.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Imię i nazwisko *',
              hintText: 'np. Jan Kowalski',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            onChanged: (_) => _syncToFormData(),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail *',
              hintText: 'np. jan@example.com',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneController,
            onChanged: (_) => _syncToFormData(),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Telefon *',
              hintText: 'np. +48 123 456 789',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _preferredTimeController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Preferowana godzina kontaktu (opcjonalnie)',
              hintText: 'np. popołudnie, 10–14',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
