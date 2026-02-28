import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/password_validator.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';
import 'nip_registration_provider.dart';

/// Krok 2 rejestracji NIP: dane kontaktowe (imię i nazwisko, stanowisko, email, telefon), hasło, "Zostań zalogowany".
class RegistrationNipDetailsStepPage extends ConsumerStatefulWidget {
  const RegistrationNipDetailsStepPage({super.key});

  @override
  ConsumerState<RegistrationNipDetailsStepPage> createState() =>
      _RegistrationNipDetailsStepPageState();
}

class _RegistrationNipDetailsStepPageState
    extends ConsumerState<RegistrationNipDetailsStepPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _stayLoggedIn = true;
  bool _hasPrefilledFromProvider = false;

  static const _stayLoggedInKey = 'nip_registration_stay_logged_in';

  @override
  void initState() {
    super.initState();
    _loadStayLoggedIn();
  }

  static String _phoneFromStored(String? stored) {
    if (stored == null || stored.isEmpty) return '';
    final t = stored.trim();
    if (t.startsWith('+48')) return t.replaceFirst(RegExp(r'^\+48\s*'), '').trim();
    return t;
  }

  void _prefillFromProvider(NipRegistrationFormData form) {
    if (_hasPrefilledFromProvider) return;
    _hasPrefilledFromProvider = true;
    _displayNameController.text = form.displayName;
    _positionController.text = form.position ?? '';
    _emailController.text = form.email;
    _phoneController.text = _phoneFromStored(form.phone);
    _passwordController.text = form.password;
    _passwordConfirmController.text = form.password;
    setState(() => _stayLoggedIn = form.stayLoggedIn);
  }

  Future<void> _loadStayLoggedIn() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final v = prefs?.getBool(_stayLoggedInKey);
      if (v != null && mounted) setState(() => _stayLoggedIn = v);
    } catch (_) {}
  }

  Future<void> _saveStayLoggedIn(bool value) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) await prefs.setBool(_stayLoggedInKey, value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(nipRegistrationFormProvider.notifier).state =
        NipRegistrationFormData(
      displayName: _displayNameController.text.trim(),
      position: _positionController.text.trim().isEmpty
          ? null
          : _positionController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? ''
          : '+48 ${_phoneController.text.trim()}',
      password: _passwordController.text,
      stayLoggedIn: _stayLoggedIn,
    );
    context.go(AppRouter.rejestracjaNipRegulamin);
  }

  @override
  Widget build(BuildContext context) {
    final subject = ref.watch(verifiedNipSubjectProvider);
    final savedForm = ref.watch(nipRegistrationFormProvider);
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (savedForm != null && !_hasPrefilledFromProvider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefillFromProvider(savedForm);
      });
    }

    if (subject == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRouter.rejestracjaNip);
      });
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
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
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Dane kontaktowe',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Krok 2 z 3 – uzupełnij dane reprezentanta firmy i ustaw hasło.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: AppColors.primaryDark),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  TextFormField(
                    controller: _displayNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(100),
                    ],
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Podaj imię i nazwisko.'
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'Imię i nazwisko',
                      hintText: 'Jan Kowalski',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _positionController,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(80),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Stanowisko (opcjonalnie)',
                      hintText: 'Dyrektor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9@._+\-]')),
                      LengthLimitingTextInputFormatter(254),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Podaj email.';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v.trim())) {
                        return 'Nieprawidłowy format email.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'jan@firma.pl',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9\s\-()]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final digitsOnly =
                          v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length != 9) {
                        return 'Wpisz 9 cyfr numeru.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Numer telefonu (opcjonalnie)',
                      hintText: '123 456 789',
                      prefixText: '+48 ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(128),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Podaj hasło.';
                      final failed =
                          PasswordValidator.getFailedRequirements(v);
                      if (failed.isNotEmpty) {
                        return 'Hasło: ${failed.join(", ")}.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Hasło',
                      hintText:
                          'Min. ${PasswordValidator.minLength} znaków, wielka/mała litera, cyfra, znak specjalny',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildChip('Wielka litera',
                          PasswordValidator.hasUppercase(_passwordController.text)),
                      _buildChip('Mała litera',
                          PasswordValidator.hasLowercase(_passwordController.text)),
                      _buildChip('Cyfra',
                          PasswordValidator.hasNumericCharacter(_passwordController.text)),
                      _buildChip('Znak specjalny',
                          PasswordValidator.hasSpecialCharacter(_passwordController.text)),
                      _buildChip('Min. ${PasswordValidator.minLength} znaków',
                          PasswordValidator.hasMinLength(_passwordController.text)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(128),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Potwierdź hasło.';
                      if (v != _passwordController.text) {
                        return 'Hasła muszą być identyczne.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Powtórz hasło',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _stayLoggedIn,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _stayLoggedIn = v);
                            await _saveStayLoggedIn(v);
                          },
                          activeColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () async {
                          final v = !_stayLoggedIn;
                          setState(() => _stayLoggedIn = v);
                          await _saveStayLoggedIn(v);
                        },
                        child: Text(
                          'Zostań zalogowany',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: const Text('Dalej – regulamin i NDA'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () {
                      ref.read(nipRegistrationFormProvider.notifier).state =
                          NipRegistrationFormData(
                        displayName: _displayNameController.text.trim(),
                        position: _positionController.text.trim().isEmpty
                            ? null
                            : _positionController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim().isEmpty
                            ? ''
                            : '+48 ${_phoneController.text.trim()}',
                        password: _passwordController.text,
                        stayLoggedIn: _stayLoggedIn,
                      );
                      context.go(AppRouter.rejestracjaNip);
                    },
                    child: Text(
                      'Wróć do weryfikacji NIP',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildChip(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Chip(
        label: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: ok ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        backgroundColor: ok
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
