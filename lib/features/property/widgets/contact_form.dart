import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/custom_button.dart';

class ContactForm extends StatefulWidget {
  /// Po pomyślnym wysłaniu (np. zamknięcie bottom sheet).
  final VoidCallback? onSuccess;

  /// Mniejszy padding – do bottom sheet / modal.
  final bool compact;

  const ContactForm({
    super.key,
    this.onSuccess,
    this.compact = false,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  static String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pole wymagane';
    if (value.trim().length < 2) return 'Podaj co najmniej 2 znaki';
    if (RegExp(r'[0-9]').hasMatch(value)) return 'Imię i nazwisko nie powinno zawierać cyfr';
    return null;
  }

  static String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pole wymagane';
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 9) return 'Numer musi mieć co najmniej 9 cyfr';
    if (RegExp(r'[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]').hasMatch(value)) {
      return 'Numer nie może zawierać liter';
    }
    return null;
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pole wymagane';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Nieprawidłowy adres email';
    }
    return null;
  }

  static String? _validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pole wymagane';
    if (value.trim().length < 10) return 'Wiadomość musi mieć co najmniej 10 znaków';
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wiadomość wysłana'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSuccess?.call();
    }
  }

  InputDecoration _contactFieldDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.grey50,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.accent,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderMedium, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderMedium, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textDisabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.compact ? AppSpacing.sm : AppSpacing.md;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compact)
            Text(
              'Zapytaj o ofertę',
              style: AppTextStyles.titleMedium,
            ),
          if (!widget.compact) SizedBox(height: padding),
          
          TextFormField(
            controller: _nameController,
            decoration: _contactFieldDecoration(
              labelText: 'Imię i nazwisko',
              hintText: 'Jan Kowalski',
            ),
            validator: _validateName,
          ),
          SizedBox(height: padding),
          
          TextFormField(
            controller: _phoneController,
            decoration: _contactFieldDecoration(
              labelText: 'Telefon',
              hintText: '+48 123 456 789',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-\(\)]')),
            ],
            validator: _validatePhone,
          ),
          SizedBox(height: padding),
          
          TextFormField(
            controller: _emailController,
            decoration: _contactFieldDecoration(
              labelText: 'Email',
              hintText: 'email@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          SizedBox(height: padding),
          
          TextFormField(
            controller: _messageController,
            decoration: _contactFieldDecoration(
              labelText: 'Wiadomość',
              hintText: 'Jestem zainteresowany ofertą...',
            ),
            maxLines: 3,
            validator: _validateMessage,
          ),
          SizedBox(height: padding),
          
          CustomButton(
            label: 'Zapytaj o ofertę',
            onPressed: _submitForm,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
