import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';

/// Krok 1 rejestracji e-mail: podanie adresu i wysłanie linku weryfikacyjnego.
class RegistrationEmailStepPage extends ConsumerStatefulWidget {
  const RegistrationEmailStepPage({super.key});

  @override
  ConsumerState<RegistrationEmailStepPage> createState() =>
      _RegistrationEmailStepPageState();
}

class _RegistrationEmailStepPageState
    extends ConsumerState<RegistrationEmailStepPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _linkSent = false;
  String? _errorMessage;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String get _continueUrl {
    final email = _emailController.text.trim();
    final origin = Uri.base.origin;
    return '$origin/rejestracja/email-link?email=${Uri.encodeComponent(email)}';
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).sendSignInLinkToEmail(
            email: email,
            continueUrl: _continueUrl,
          );
      if (!mounted) return;
      setState(() {
        _linkSent = true;
        _sentToEmail = email;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String msg = 'Nie udało się wysłać linku. Spróbuj ponownie.';
      final err = e.toString().toLowerCase();
      if (err.contains('email-already-in-use') || err.contains('already in use')) {
        msg = 'Ten adres e-mail jest już zarejestrowany. Zaloguj się.';
      } else if (err.contains('invalid-email')) {
        msg = 'Nieprawidłowy adres e-mail.';
      } else if (err.contains('too-many-requests')) {
        msg = 'Zbyt wiele prób. Poczekaj chwilę i spróbuj ponownie.';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Rejestracja',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!_linkSent) ...[
                  Text(
                    'Krok 1 z 3 – podaj adres e-mail. Wyślemy na niego link weryfikacyjny.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Link weryfikacyjny został wysłany',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Na adres $_sentToEmail wysłaliśmy link weryfikacyjny. '
                    'Kliknij go w wiadomości e-mail, aby przejść do kolejnego kroku rejestracji.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: AppColors.primaryDark.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Nie widzisz wiadomości? Sprawdź folder „Oferty” lub „Spam”.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _linkSent = false;
                      _sentToEmail = null;
                    }),
                    child: const Text('Wpisz inny adres e-mail'),
                  ),
                ],
                if (!_linkSent) ...[
                  const SizedBox(height: AppSpacing.xxl),
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
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enabled: !_isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9@._+\-]'),
                            ),
                            LengthLimitingTextInputFormatter(254),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Podaj adres e-mail.';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v.trim())) {
                              return 'Nieprawidłowy format e-mail.';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Adres e-mail',
                            hintText: 'jan@example.com',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: _isLoading ? null : _sendLink,
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
                              : const Text('Wyślij link weryfikacyjny'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go(AppRouter.rejestracja),
                  child: Text(
                    'Wróć do wyboru metody rejestracji',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
