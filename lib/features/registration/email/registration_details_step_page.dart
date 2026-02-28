import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/password_validator.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';

/// Krok 2 rejestracji e-mail: imię, nazwisko, kod pocztowy (opcjonalnie), hasło, "Zostań zalogowany".
class RegistrationDetailsStepPage extends ConsumerStatefulWidget {
  const RegistrationDetailsStepPage({super.key});

  @override
  ConsumerState<RegistrationDetailsStepPage> createState() =>
      _RegistrationDetailsStepPageState();
}

class _RegistrationDetailsStepPageState
    extends ConsumerState<RegistrationDetailsStepPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _stayLoggedIn = true;
  String? _errorMessage;

  static const _stayLoggedInKey = 'registration_stay_logged_in';

  @override
  void initState() {
    super.initState();
    _loadStayLoggedIn();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _postalCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authServiceProvider);
    if (kIsWeb) {
      await auth.setPersistence(
        _stayLoggedIn ? Persistence.LOCAL : Persistence.SESSION,
      );
    }

    try {
      final displayName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final postalCode = _postalCodeController.text.trim();
      await auth.setPasswordAndProfile(
        displayName: displayName,
        password: _passwordController.text,
        postalCode: postalCode.isEmpty ? null : postalCode,
      );
      await _saveStayLoggedIn(_stayLoggedIn);
      if (!mounted) return;
      context.go(AppRouter.rejestracjaRegulamin);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Nie udało się zapisać danych. Spróbuj ponownie.';
      final err = e.toString().toLowerCase();
      if (err.contains('requires-recent-login')) {
        msg = 'Sesja wygasła. Kliknij ponownie link weryfikacyjny z e-maila.';
      } else if (err.contains('weak-password')) {
        msg = 'Hasło nie spełnia wymagań (wielka litera, mała, cyfra, znak specjalny, min. ${PasswordValidator.minLength} znaków).';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRouter.rejestracja);
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Dane konta',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Krok 2 z 3 – uzupełnij dane i ustaw hasło.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Podaj imię.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Imię',
                      hintText: 'Jan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Podaj nazwisko.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nazwisko',
                      hintText: 'Kowalski',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\- ]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Kod pocztowy (opcjonalnie)',
                      hintText: '00-001',
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
                      if (v == null || v.isEmpty) {
                        return 'Podaj hasło.';
                      }
                      final failed = PasswordValidator.getFailedRequirements(v);
                      if (failed.isNotEmpty) {
                        return 'Hasło: ${failed.join(", ")}.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Hasło',
                      hintText: 'Min. ${PasswordValidator.minLength} znaków, wielka/mała litera, cyfra, znak specjalny',
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
                      _buildRequirementChip('Wielka litera', PasswordValidator.hasUppercase(_passwordController.text)),
                      _buildRequirementChip('Mała litera', PasswordValidator.hasLowercase(_passwordController.text)),
                      _buildRequirementChip('Cyfra', PasswordValidator.hasNumericCharacter(_passwordController.text)),
                      _buildRequirementChip('Znak specjalny', PasswordValidator.hasSpecialCharacter(_passwordController.text)),
                      _buildRequirementChip('Min. ${PasswordValidator.minLength} znaków', PasswordValidator.hasMinLength(_passwordController.text)),
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
                          onChanged: _isLoading
                              ? null
                              : (v) async {
                                  if (v == null) return;
                                  setState(() => _stayLoggedIn = v);
                                  await _saveStayLoggedIn(v);
                                },
                          activeColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () async {
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
                  if (_errorMessage != null) ...[
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
                              _errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Dalej'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: Text(
                      'Anuluj rejestrację',
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

  Widget _buildRequirementChip(String label, bool ok) {
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
