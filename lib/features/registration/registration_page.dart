import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/linkedin_auth.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

/// Strona rejestracji: OAuth (Google/Apple) lub Rejestracja firmowa (NIP).
/// Po OAuth użytkownik trafia na "Dokończ rejestrację".
class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      await _redirectAfterAuth(cred?.user);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await ref.read(authServiceProvider).signInWithApple();
      if (!mounted) return;
      await _redirectAfterAuth(cred?.user);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Na web: przekierowanie synchroniczne, żeby LinkedIn otworzył się w tej samej karcie (bez iframe).
  void _handleLinkedInSignIn() {
    if (!kIsWeb) return;
    final url = buildLinkedInAuthUrl(AppRouter.dashboard);
    if (url == null || url.isEmpty) return;
    redirectToLinkedIn(url);
  }

  Future<void> _redirectAfterAuth(User? user) async {
    if (!mounted || user == null) return;
    final appUser = await ref.read(authServiceProvider).getAppUser(user.uid, user);
    if (!mounted) return;
    if (appUser?.hasIdentityVerifiedAccess == true) {
      context.go(AppRouter.dashboard);
    } else {
      context.go('${AppRouter.rejestracjaDokoncz}?returnTo=${Uri.encodeComponent(AppRouter.dashboard)}');
    }
  }

  String _formatAuthError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('sign_in_canceled') || msg.contains('CANCELLED')) {
      return 'Rejestracja została anulowana.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Ten adres email jest już zarejestrowany. Zaloguj się.';
    }
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final showApple = !kIsWeb;
    final showLinkedIn = kIsWeb;

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
                  'Zarejestruj się',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kontynuuj przez Google, Apple lub LinkedIn, zarejestruj się e-mailem lub firmą (NIP).',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
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

                _AuthButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Kontynuuj z Google',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (showApple) ...[
                  _AuthButton(
                    onPressed: _isLoading ? null : _handleAppleSignIn,
                    icon: Icons.apple,
                    label: 'Kontynuuj z Apple',
                    useDarkStyle: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (showLinkedIn) ...[
                  _AuthButton(
                    onPressed: _isLoading ? null : _handleLinkedInSignIn,
                    icon: Icons.work_outline,
                    label: 'Kontynuuj z LinkedIn',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text(
                        'lub',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(AppRouter.rejestracjaEmail),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('Zarejestruj się e-mailem'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(AppRouter.rejestracjaNip),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('Rejestracja firmowa (NIP)'),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go(AppRouter.logowanie),
                  child: Text(
                    'Masz już konto? Zaloguj się',
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

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.useDarkStyle = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool useDarkStyle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: useDarkStyle ? AppColors.primaryDark : null,
        foregroundColor:
            useDarkStyle ? AppColors.white : AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }
}
