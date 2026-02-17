import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth/password_validator.dart';
import '../../core/config/app_config.dart';
import '../../core/services/wl_api_client.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/nda_modal.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

void _regLog(String message, [Object? detail]) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('[NipReg] $message${detail != null ? ' $detail' : ''}');
  }
}

/// Rejestracja firmowa przez NIP: weryfikacja NIP, autouzupełnienie firmy, dane kontaktowe, hasło, NDA.
class NipRegistrationPage extends ConsumerStatefulWidget {
  const NipRegistrationPage({super.key});

  @override
  ConsumerState<NipRegistrationPage> createState() =>
      _NipRegistrationPageState();
}

class _NipRegistrationPageState extends ConsumerState<NipRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _wlClient = WlApiClient();
  WlSubject? _nipSubject;
  bool _nipLoading = false;
  String? _nipError;
  bool _ndaAccepted = false;
  bool _ndaScrolledToEnd = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _submitLoading = false;
  String? _submitError;
  bool _success = false;

  @override
  void dispose() {
    _nipController.dispose();
    _displayNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyNip() async {
    final nip =
        _nipController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (nip.length != 10) {
      setState(() {
        _nipError = 'NIP musi mieć 10 cyfr';
        _nipSubject = null;
      });
      return;
    }
    setState(() {
      _nipError = null;
      _nipSubject = null;
      _nipLoading = true;
    });
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final subject = await _wlClient.searchByNip(nip, date: date);
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _nipSubject = subject;
        if (subject == null) {
          _nipError =
              'Firma o tym NIP jest wykreślona z rejestru VAT lub NIP nie istnieje. '
              'Skontaktuj się z nami: ${AppConfig.contactEmail}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _nipSubject = null;
        _nipError =
            'Błąd połączenia z rejestrem. Spróbuj później lub skontaktuj się: ${AppConfig.contactEmail}';
      });
    }
  }

  Future<void> _openNdaModal() async {
    final result = await NdaModal.show(context);
    if (result != null && mounted) {
      setState(() {
        _ndaAccepted = result.accepted;
        _ndaScrolledToEnd = result.scrolledToEnd;
      });
    }
  }

  Future<void> _submit() async {
    _regLog('_submit start');
    if (_nipSubject == null) {
      setState(() => _submitError = 'Najpierw zweryfikuj NIP (przycisk „Weryfikuj NIP”).');
      return;
    }
    if (!_ndaAccepted) {
      setState(() => _submitError = 'Wymagana akceptacja Regulaminu i NDA – zaznacz checkbox i przeczytaj NDA.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _regLog('_submit: walidacja nie przeszła');
      return;
    }

    setState(() {
      _submitError = null;
      _submitLoading = true;
    });
    try {
      _regLog('_submit: wywołanie registerWithNip');
      final auth = ref.read(authServiceProvider);
      final s = _nipSubject!;
      await auth.registerWithNip(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        phone: _phoneController.text.trim(),
        nip: s.nip,
        companyName: s.name,
        companyAddress: s.residenceAddress ?? s.workingAddress ?? '',
        ndaAccepted: true,
        ndaScrolledToEnd: _ndaScrolledToEnd,
        companyRegon: s.regon,
        companyStatusVat: s.statusVat,
        companyResidenceAddress: s.residenceAddress,
        companyWorkingAddress: s.workingAddress,
      );
      _regLog('_submit: registerWithNip zakończone');
      if (!mounted) {
        _regLog('_submit: unmounted po registerWithNip');
        return;
      }
      setState(() {
        _submitLoading = false;
        _success = true;
      });
      _regLog('_submit: setState success=true');
    } catch (e, st) {
      _regLog('_submit: błąd', e);
      if (kDebugMode) {
        // ignore: avoid_print
        print(st);
      }
      if (mounted) {
        setState(() {
          _submitLoading = false;
          _submitError = e.toString().contains('email-already-in-use')
              ? 'Ten adres email jest już zarejestrowany.'
              : 'Nie udało się utworzyć konta. Spróbuj ponownie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (_success) {
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Konto utworzone',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Na adres ${_emailController.text} wysłaliśmy link weryfikacyjny. '
                  'Potwierdź email w ciągu 24h, aby uzyskać pełny dostęp do ofert.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: () => context.go(AppRouter.logowanie),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Przejdź do logowania'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Rejestracja firmowa',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aby założyć konto firmowe:',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildStepRow(1, 'Zweryfikuj NIP (przycisk „Weryfikuj NIP”)', _nipSubject != null),
                        _buildStepRow(2, 'Wypełnij dane kontaktowe i hasło', _nipSubject != null),
                        _buildStepRow(3, 'Zaakceptuj Regulamin i NDA', _ndaAccepted),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Krok 1: NIP
                  Text(
                    'Krok 1: NIP firmy*',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nipController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: 'np. 1234567890',
                            errorText: _nipError,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {
                            _nipError = null;
                            _nipSubject = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _nipLoading ? null : _verifyNip,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                        ),
                        child: _nipLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Weryfikuj NIP'),
                      ),
                    ],
                  ),
                  if (_nipSubject != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Firma zweryfikowana: ${_nipSubject!.name}',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_nipSubject!.regon != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'REGON: ${_nipSubject!.regon}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_nipSubject!.statusVat != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Status VAT: ${_nipSubject!.statusVat}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_nipSubject!.residenceAddress != null ||
                              _nipSubject!.workingAddress != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _nipSubject!.residenceAddress ??
                                  _nipSubject!.workingAddress ??
                                  '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  // Krok 2: Dane kontaktowe (odblokowane dopiero po NIP)
                  if (_nipSubject == null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Zweryfikuj NIP, aby odblokować pola poniżej i móc założyć konto.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_nipSubject == null) const SizedBox(height: AppSpacing.lg),
                  IgnorePointer(
                    ignoring: _nipSubject == null,
                    child: Opacity(
                      opacity: _nipSubject != null ? 1 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                  Text(
                    'Krok 2: Dane kontaktowe',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _displayNameController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Imię i nazwisko*',
                      hintText: 'Jan Kowalski',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Podaj imię i nazwisko.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _positionController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(80),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Stanowisko',
                      hintText: 'Dyrektor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(254),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Email*',
                      hintText: 'jan@firma.pl',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Podaj email.';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v.trim())) {
                        return 'Nieprawidłowy format email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Telefon*',
                      hintText: '+48 123 456 789',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Podaj telefon.';
                      if (RegExp(r'[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]').hasMatch(v)) {
                        return 'Numer telefonu może zawierać tylko cyfry oraz znaki +, -, spacje, nawiasy.';
                      }
                      final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length < 9) {
                        return 'Numer telefonu musi zawierać co najmniej 9 cyfr.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Hasło
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(128),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Hasło*',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Podaj hasło.';
                      final failed =
                          PasswordValidator.getFailedRequirements(v);
                      if (failed.isNotEmpty) {
                        return 'Hasło musi spełniać wymagania (wielka, mała, cyfra, znak specjalny, min. 8 znaków).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: _obscurePasswordConfirm,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(128),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Powtórz hasło*',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirm
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() =>
                            _obscurePasswordConfirm = !_obscurePasswordConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Hasła muszą być identyczne.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Krok 3: NDA
                  Text(
                    'Krok 3: Regulamin i NDA*',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _ndaAccepted,
                          onChanged: _nipSubject != null
                              ? (v) => setState(() => _ndaAccepted = v ?? false)
                              : null,
                          activeColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akceptuję Regulamin i NDA*',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openNdaModal,
                              child: Text(
                                'Przeczytaj NDA',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.accent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (_submitError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Przycisk odblokowany tylko przy zweryfikowanym NIP i zaakceptowanym NDA
                  if (_nipSubject == null || !_ndaAccepted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        _nipSubject == null
                            ? 'Zweryfikuj NIP (krok 1), aby odblokować rejestrację.'
                            : 'Zaakceptuj Regulamin i NDA (krok 3), aby założyć konto.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: (_nipSubject != null && _ndaAccepted && !_submitLoading)
                        ? _submit
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: _submitLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Zarejestruj się'),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // RODO
                  Text(
                    'Administratorem danych osobowych jest ${AppConfig.dataControllerName}. '
                    'Twoje dane będą przetwarzane w celu świadczenia usług platformy. '
                    'Przysługuje Ci prawo dostępu, sprostowania i usunięcia danych. '
                    'Pełna polityka prywatności dostępna na stronie.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int step, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$step. $label',
              style: AppTextStyles.bodySmall.copyWith(
                color: done ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
