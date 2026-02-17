import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/roi_models.dart';
import '../utils/roi_email_helper.dart';
import '../services/roi_calculation_email_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/state/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal „Zapisz kalkulację na email”: pole adresu, wysyłka przez Cloud Function lub mailto.
class RoiSaveToEmailModal extends ConsumerStatefulWidget {
  const RoiSaveToEmailModal({
    super.key,
    required this.inputs,
    required this.results,
    this.advancedInputs,
    this.advancedResults,
  });

  final RoiQuickInputs inputs;
  final RoiQuickResults results;
  final RoiAdvancedInputs? advancedInputs;
  final RoiAdvancedResults? advancedResults;

  @override
  ConsumerState<RoiSaveToEmailModal> createState() => _RoiSaveToEmailModalState();
}

class _RoiSaveToEmailModalState extends ConsumerState<RoiSaveToEmailModal> {
  late TextEditingController _emailController;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillEmail());
  }

  void _prefillEmail() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.email != null && user!.email!.trim().isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String get _subject => RoiEmailHelper.subject(widget.results);

  String get _body => RoiEmailHelper.body(
        inputs: widget.inputs,
        results: widget.results,
        advancedInputs: widget.advancedInputs,
        advancedResults: widget.advancedResults,
      );

  Future<void> _sendViaApi() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Podaj adres e-mail';
      });
      return;
    }
    if (!RoiCalculationEmailService.isValidEmail(email)) {
      setState(() {
        _error = 'Nieprawidłowy format adresu e-mail';
      });
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });

    final result = await RoiCalculationEmailService.send(
      email: email,
      subject: _subject,
      body: _body,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case RoiEmailSendResult.success:
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kalkulacja została wysłana na podany adres e-mail.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case RoiEmailSendResult.notConfigured:
        setState(() {
          _error = 'Wysyłka e-mail jest tymczasowo niedostępna. Użyj „Otwórz w programie e-mail”.';
        });
        break;
      case RoiEmailSendResult.invalidEmail:
        setState(() => _error = 'Nieprawidłowy adres e-mail.');
        break;
      case RoiEmailSendResult.networkError:
        setState(() => _error = 'Błąd połączenia. Sprawdź internet lub użyj „Otwórz w programie e-mail”.');
        break;
    }
  }

  Future<void> _openMailto() async {
    final email = _emailController.text.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: email.isEmpty ? '' : email,
      queryParameters: {'subject': _subject, 'body': _body},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          setState(() => _error = 'Nie można otworzyć programu e-mail.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nie można otworzyć programu e-mail.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zapisz kalkulację na e-mail'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Podaj adres e-mail, na który wysłać podsumowanie kalkulacji.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Adres e-mail',
                hintText: 'np. jan@example.com',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ROI: ${widget.results.roi.toStringAsFixed(1)}% · Okres zwrotu: ${widget.results.paybackYears.toStringAsFixed(1)} lat',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: _sending ? null : _openMailto,
          child: const Text('Otwórz w programie e-mail'),
        ),
        FilledButton(
          onPressed: _sending ? null : _sendViaApi,
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Wyślij na ten adres'),
        ),
      ],
    );
  }
}
