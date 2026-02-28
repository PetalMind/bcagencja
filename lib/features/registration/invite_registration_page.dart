import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/password_validator.dart';
import '../../core/config/app_config.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

/// Rejestracja z linku zaproszeniowego (Agent/Dyrektor). Email z tokena jest tylko do odczytu.
class InviteRegistrationPage extends ConsumerStatefulWidget {
  const InviteRegistrationPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteRegistrationPage> createState() =>
      _InviteRegistrationPageState();
}

class _InviteRegistrationPageState extends ConsumerState<InviteRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _regulaminAccepted = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _submitLoading = false;
  String? _submitError;
  bool _loadingInvite = true;
  String? _inviteError;
  String? _inviteEmail;
  String? _inviteRole;
  String? _inviteRegion;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    final auth = ref.read(authServiceProvider);
    final invite = await auth.getInviteByToken(widget.token);
    if (!mounted) return;
    setState(() {
      _loadingInvite = false;
      if (invite != null) {
        _inviteEmail = invite.email;
        _inviteRole = invite.role == 'director' ? 'Dyrektor' : 'Agent';
        _inviteRegion = invite.regionVoivodeship;
      } else {
        _inviteError = 'Nieprawidłowy lub wygasły link zaproszeniowy.';
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_regulaminAccepted) {
      setState(() => _submitError = 'Wymagana akceptacja Regulaminu.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitError = null;
      _submitLoading = true;
    });
    try {
      final auth = ref.read(authServiceProvider);
      await auth.completeInviteRegistration(
        token: widget.token,
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? ''
            : '+48 ${_phoneController.text.trim()}',
        password: _passwordController.text,
        regulaminAccepted: true,
      );
      if (!mounted) return;
      context.go(AppRouter.dashboard);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitLoading = false;
          _submitError = e.toString().contains('email-already-in-use')
              ? 'Konto z tym adresem email już istnieje.'
              : 'Nie udało się aktywować konta. Spróbuj ponownie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (_loadingInvite) {
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_inviteError != null) {
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _inviteError!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go(AppRouter.home),
                  child: const Text('Strona główna'),
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Zaproszenie do platformy',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_inviteRole != null || _inviteRegion != null)
                    Text(
                      [
                        if (_inviteRole != null) 'Rola: $_inviteRole',
                        if (_inviteRegion != null) 'Region: $_inviteRegion',
                      ].join(' | '),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),

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
                        v == null || v.trim().isEmpty
                            ? 'Podaj imię i nazwisko.'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: _inviteEmail,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email*',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-()]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Numer telefonu (opcjonalnie)',
                      hintText: '123 456 789',
                      prefixText: '+48 ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length != 9) {
                        return 'Wpisz 9 cyfr numeru.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _regulaminAccepted,
                          onChanged: (v) =>
                              setState(() => _regulaminAccepted = v ?? false),
                          activeColor: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Akceptuję Regulamin*',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

                  FilledButton(
                    onPressed: _submitLoading ? null : _submit,
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
                        : const Text('Aktywuj konto'),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Administratorem danych osobowych jest ${AppConfig.dataControllerName}. '
                    'Twoje dane będą przetwarzane w celu świadczenia usług platformy. '
                    'Przysługuje Ci prawo dostępu, sprostowania i usunięcia danych.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
}
