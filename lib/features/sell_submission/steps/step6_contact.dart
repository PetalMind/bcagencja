import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/app_user.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../input_formatters.dart';
import '../listing_submission_model.dart';

/// Krok 6: Dane kontaktowe – imię, email, telefon, preferencje, checkboxes, "Co się stanie dalej".
class Step6Contact extends ConsumerStatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final bool readOnly;

  const Step6Contact({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.readOnly = false,
  });

  @override
  ConsumerState<Step6Contact> createState() => _Step6ContactState();
}

class _Step6ContactState extends ConsumerState<Step6Contact> {
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

  void _fillFromAccount(AppUser user) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.companyName?.trim().isNotEmpty == true ? user.companyName!.trim() : null);
    final email = user.email?.trim().isNotEmpty == true ? user.email!.trim() : null;
    final phone = user.phone?.trim().isNotEmpty == true ? user.phone!.trim() : null;

    _nameController.text = name ?? '';
    _emailController.text = email ?? '';
    _phoneController.text = phone ?? '';
    _syncToFormData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final canFillFromAccount = !widget.readOnly &&
        user != null &&
        (user.displayName?.trim().isNotEmpty == true ||
            user.companyName?.trim().isNotEmpty == true ||
            user.email?.trim().isNotEmpty == true ||
            user.phone?.trim().isNotEmpty == true);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              if (canFillFromAccount)
                OutlinedButton.icon(
                  onPressed: () => _fillFromAccount(user),
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('Uzupełnij z konta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _nameController,
            readOnly: widget.readOnly,
            onChanged: widget.readOnly ? null : (_) => _syncToFormData(),
            maxLength: kMaxNameLength,
            decoration: InputDecoration(
              labelText: 'Imię i nazwisko / Nazwa firmy *',
              hintText: 'np. Jan Kowalski',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
              counterText: '',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            readOnly: widget.readOnly,
            onChanged: widget.readOnly ? null : (_) => _syncToFormData(),
            keyboardType: TextInputType.emailAddress,
            maxLength: kMaxEmailLength,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Podaj adres email';
              if (!RegExp(r'^[\w\-+.]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(t)) {
                return 'Nieprawidłowy format email';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email *',
              hintText: 'np. jan@example.com',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneController,
            readOnly: widget.readOnly,
            onChanged: widget.readOnly ? null : (_) => _syncToFormData(),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              phoneInputFormatter,
              LengthLimitingTextInputFormatter(kMaxPhoneLength),
            ],
            decoration: InputDecoration(
              labelText: 'Telefon *',
              hintText: '+48 123 456 789',
              helperText: 'Tylko cyfry i znaki + - ( )',
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
            onChanged: widget.readOnly ? null : (v) {
              widget.formData.contactByEmail = v ?? true;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Email', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.contactByPhone,
            onChanged: widget.readOnly ? null : (v) {
              widget.formData.contactByPhone = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Telefon', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.contactByWhatsApp,
            onChanged: widget.readOnly ? null : (v) {
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
            readOnly: widget.readOnly,
            onChanged: widget.readOnly ? null : (_) => _syncToFormData(),
            maxLength: kMaxShortTextLength,
            decoration: InputDecoration(
              labelText: 'Kiedy możemy zadzwonić? (opcjonalnie)',
              hintText: 'np. 9–17, jak najszybciej',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CheckboxListTile(
            value: widget.formData.acceptedPrivacy,
            onChanged: widget.readOnly ? null : (v) {
              widget.formData.acceptedPrivacy = v ?? false;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
            title: Text('Akceptuję politykę prywatności i regulamin', style: AppTextStyles.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: widget.formData.acceptedContact,
            onChanged: widget.readOnly ? null : (v) {
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
