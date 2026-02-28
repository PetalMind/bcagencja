import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/linkedin_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/favorites_provider.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../core/theme/app_icons.dart';

void _loginLog(String message, [Object? detail]) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('[Login] $message${detail != null ? ' $detail' : ''}');
  }
}

/// Strona logowania – Google, Apple, Email/Password.
/// [returnTo] – ścieżka do przekierowania po zalogowaniu (np. /oferty, /property/1).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true;
  bool _obscurePassword = true;

  static const _rememberMeKey = 'login_remember_me';

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final v = prefs?.getBool(_rememberMeKey);
      if (v != null && mounted) setState(() => _rememberMe = v);
    } catch (_) {}
  }

  Future<void> _saveRememberMe(bool value) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) await prefs.setBool(_rememberMeKey, value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _redirectAfterLogin(User? user) async {
    _loginLog('_redirectAfterLogin', 'user=${user?.uid} mounted=$mounted');
    if (!mounted || user == null) {
      _loginLog('_redirectAfterLogin: pominięto (brak user lub unmounted)');
      return;
    }
    try {
      _loginLog('_redirectAfterLogin: getAppUser');
      final appUser = await ref.read(authServiceProvider).getAppUser(user.uid, user);
      final target = widget.returnTo ?? AppRouter.dashboard;
      _loginLog('_redirectAfterLogin: appUser=${appUser != null} hasIdentity=${appUser?.hasIdentityVerifiedAccess} ndaAccepted=${appUser?.ndaAcceptedAt != null} target=$target');
      if (!mounted) {
        _loginLog('_redirectAfterLogin: unmounted po getAppUser');
        return;
      }
      if (appUser?.hasIdentityVerifiedAccess == true) {
        _loginLog('_redirectAfterLogin: context.go(target)');
        if (mounted) setState(() => _isLoading = false);
        context.go(target);
      } else if (appUser?.ndaAcceptedAt != null) {
        _loginLog('_redirectAfterLogin: context.go(target) (NDA)');
        if (mounted) setState(() => _isLoading = false);
        context.go(target);
      } else {
        _loginLog('_redirectAfterLogin: context.go(rejestracjaDokoncz)');
        if (mounted) setState(() => _isLoading = false);
        context.go('${AppRouter.rejestracjaDokoncz}?returnTo=${Uri.encodeComponent(target)}');
      }
    } catch (e, st) {
      _loginLog('_redirectAfterLogin: błąd', e);
      if (kDebugMode) {
        // ignore: avoid_print
        print(st);
      }
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(AppRouter.dashboard);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _loginLog('_handleGoogleSignIn start');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      _loginLog('_handleGoogleSignIn: cred=${cred != null} user=${cred?.user?.uid}');
      if (mounted) await _redirectAfterLogin(cred?.user);
    } catch (e) {
      _loginLog('_handleGoogleSignIn: błąd', e);
      if (mounted) {
        setState(() {
          _errorMessage = _formatAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    _loginLog('_handleAppleSignIn start');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await ref.read(authServiceProvider).signInWithApple();
      _loginLog('_handleAppleSignIn: cred=${cred != null} user=${cred?.user?.uid}');
      if (mounted) await _redirectAfterLogin(cred?.user);
    } catch (e) {
      _loginLog('_handleAppleSignIn: błąd', e);
      if (mounted) {
        setState(() {
          _errorMessage = _formatAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Na web: przekierowanie musi być synchroniczne (bez await), żeby strona LinkedIn
  /// otworzyła się w tej samej karcie, a nie w iframe (CSP / content blocker).
  void _handleLinkedInSignIn() {
    _loginLog('_handleLinkedInSignIn start');
    if (!kIsWeb) return;
    final url = buildLinkedInAuthUrl(widget.returnTo);
    if (url == null || url.isEmpty) {
      setState(() {
        _errorMessage = 'Logowanie przez LinkedIn nie jest dostępne (brak konfiguracji lub tylko na web).';
      });
      return;
    }
    redirectToLinkedIn(url);
  }

  Future<void> _handleEmailPasswordSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _loginLog('_handleEmailPasswordSubmit start');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final auth = ref.read(authServiceProvider);
    if (kIsWeb) {
      await auth.setPersistence(
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _loginLog('_handleEmailPasswordSubmit: signIn OK uid=${cred.user?.uid}');
      if (mounted) {
        await _redirectAfterLogin(cred.user);
      }
    } catch (e) {
      _loginLog('_handleEmailPasswordSubmit: błąd', e);
      if (mounted) {
        setState(() {
          _errorMessage = _formatAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  String _formatAuthError(dynamic e) {
    final msg = e.toString().toLowerCase();
    final code = e is FirebaseAuthException ? e.code.toLowerCase() : '';

    if (code.contains('sign_in_canceled') || msg.contains('cancelled')) {
      return 'Logowanie zostało anulowane.';
    }
    if (code.contains('user-not-found')) return 'Nie znaleziono użytkownika.';
    if (code.contains('wrong-password') || code.contains('invalid-credential')) {
      return 'Nieprawidłowy email lub hasło.';
    }
    if (code.contains('email-already-in-use')) {
      return 'Ten adres email jest już zarejestrowany.';
    }
    if (code.contains('weak-password')) return 'Hasło jest zbyt słabe (min. 6 znaków).';
    if (code.contains('invalid-email')) return 'Nieprawidłowy adres email.';
    if (code.contains('network') || code.contains('network-request-failed')) {
      return 'Błąd sieci. Sprawdź połączenie internetowe.';
    }
    if (code.contains('too-many-requests')) {
      return 'Zbyt wiele prób. Poczekaj chwilę i spróbuj ponownie.';
    }
    if (code.contains('operation-not-allowed')) {
      return 'Logowanie e-mailem jest wyłączone. Skontaktuj się z administratorem.';
    }
    if (code.contains('user-disabled')) return 'To konto zostało zablokowane.';
    if (code.contains('requires-recent-login')) {
      return 'Zaloguj się ponownie i spróbuj jeszcze raz.';
    }
    if (msg.contains('user-not-found')) return 'Nie znaleziono użytkownika.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Nieprawidłowy email lub hasło.';
    }
    if (msg.contains('network')) return 'Błąd sieci. Sprawdź połączenie internetowe.';
    if (kDebugMode) debugPrint('Auth error (unhandled): $e');
    return 'Wystąpił błąd logowania. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(blockedMessageProvider, (prev, next) {
      final msg = next;
      if (msg != null && msg.isNotEmpty && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.error),
            );
            ref.read(blockedMessageProvider.notifier).state = null;
          }
        });
      }
    });

    final user = ref.watch(currentUserProvider).asData?.value;
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final showApple = !kIsWeb; // Apple na web wymaga dodatkowej konfiguracji
    final showLinkedIn = kIsWeb; // LinkedIn OAuth przez redirect tylko na web

    // Już zalogowany – przekieruj do returnTo lub dokończ rejestrację / dashboard
    if (user != null && !user.isBlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = widget.returnTo ?? AppRouter.dashboard;
        if (user.hasIdentityVerifiedAccess) {
          context.go(target);
        } else if (user.ndaAcceptedAt != null) {
          // NIP user – NDA już zaakceptowane, czeka na weryfikację email
          context.go(target);
        } else {
          // OAuth user bez NDA – dokończ rejestrację (osoba/firma, NDA)
          final dokonczPath = '${AppRouter.rejestracjaDokoncz}?returnTo=${Uri.encodeComponent(target)}';
          context.go(dokonczPath);
        }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Icon(
                  AppIcons.login,
                  size: 48,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Zaloguj się',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Zaloguj się przez Google, Apple, LinkedIn lub e-mail i hasło.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _isLoading ? null : () => context.go(AppRouter.rejestracja),
                  child: Text(
                    'Nie masz konta? Zarejestruj się',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
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

                // Google
                _AuthButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Kontynuuj z Google',
                ),
                const SizedBox(height: AppSpacing.sm),

                // Apple (tylko iOS/Android/macOS)
                if (showApple) ...[
                  _AuthButton(
                    onPressed: _isLoading ? null : _handleAppleSignIn,
                    icon: Icons.apple,
                    label: 'Kontynuuj z Apple',
                    useDarkStyle: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // LinkedIn (tylko web – OAuth redirect)
                if (showLinkedIn) ...[
                  _AuthButton(
                    onPressed: _isLoading ? null : _handleLinkedInSignIn,
                    icon: Icons.work_outline,
                    label: 'Kontynuuj z LinkedIn',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.md),

                // Email / Password
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9@._+\-]'),
                          ),
                          LengthLimitingTextInputFormatter(254),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Podaj adres email.';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v.trim())) {
                            return 'Nieprawidłowy format email.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'jan@example.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _handleEmailPasswordSubmit();
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Podaj hasło.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Hasło',
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
                      Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: _isLoading
                                    ? null
                                    : (v) async {
                                        if (v == null) return;
                                        setState(() => _rememberMe = v);
                                        await _saveRememberMe(v);
                                      },
                                activeColor: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final v = !_rememberMe;
                                      setState(() => _rememberMe = v);
                                      await _saveRememberMe(v);
                                    },
                              child: Text(
                                'Zapamiętaj mnie',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailPasswordSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Zaloguj się'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.go(AppRouter.home),
                  child: const Text('Wróć na stronę główną'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          isMobile ? const BottomNavBar(currentIndex: 0) : null,
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
        foregroundColor: useDarkStyle ? AppColors.white : AppColors.primaryDark,
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

