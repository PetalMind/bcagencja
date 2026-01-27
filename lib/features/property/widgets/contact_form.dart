import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wiadomość wysłana')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Zapytaj o ofertę',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Imię i nazwisko',
              hintText: 'Jan Kowalski',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pole wymagane';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '+48 123 456 789',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pole wymagane';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'email@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pole wymagane';
              }
              if (!value.contains('@')) {
                return 'Nieprawidłowy adres email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Wiadomość',
              hintText: 'Jestem zainteresowany ofertą...',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pole wymagane';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Zapytaj o ofertę'),
          ),
        ],
      ),
    );
  }
}
