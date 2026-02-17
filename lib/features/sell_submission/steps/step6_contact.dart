import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 6: Dane kontaktowe – imię, email, telefon, preferencje, checkboxes, "Co się stanie dalej".
class Step6Contact extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;

  const Step6Contact({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step6Contact> createState() => _Step6ContactState();
}

class _Step6ContactState extends State<Step6Contact> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _preferredTimeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.formData.contactName ?? '');
    _emailController = TextEditingController(text: widget.formData.contactEmail ?? '');
    _phoneController = TextEditingController(text: widget.formData.contactPhone ?? '');
    _preferredTimeController = TextEditingController(text: widget.formData.preferredContactTime ?? '');
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
    widget.formData.contactName = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    widget.formData.contactEmail = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    widget.formData.contactPhone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    widget.formData.preferredContactTime =
        _preferredTimeController.text.trim().isEmpty ? null : _preferredTimeController.text.trim();
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
            'Ostatni krok! 🎉',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Jak się z Tobą skontaktować?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Imię i nazwisko / Nazwa firmy *',
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
              labelText: 'Email *',
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
              hintText: '+48 123 456 789',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Preferowany sposób kontaktu:',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: widget.formData.contactByEmail,
            onChanged: (v) {
              widget.formData.contactByEmail = v ?? true;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Email', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.contactByPhone,
            onChanged: (v) {
              widget.formData.contactByPhone = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Telefon', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.contactByWhatsApp,
            onChanged: (v) {
              widget.formData.contactByWhatsApp = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('WhatsApp', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _preferredTimeController,
            onChanged: (_) => _syncToFormData(),
            decoration: InputDecoration(
              labelText: 'Kiedy możemy zadzwonić? (opcjonalnie)',
              hintText: 'np. 9–17, jak najszybciej',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CheckboxListTile(
            value: widget.formData.acceptedPrivacy,
            onChanged: (v) {
              widget.formData.acceptedPrivacy = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Akceptuję politykę prywatności i regulamin', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.acceptedContact,
            onChanged: (v) {
              widget.formData.acceptedContact = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Zgadzam się na kontakt w sprawie wyceny', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Co się stanie dalej?',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _nextStep('Dostaniesz potwierdzenie na email w 5 minut'),
          _nextStep('Nasz ekspert skontaktuje się w ciągu 24h'),
          _nextStep('Otrzymasz wycenę w ciągu 48h'),
        ],
      ),
    );
  }

  Widget _nextStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
