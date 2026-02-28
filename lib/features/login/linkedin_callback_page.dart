import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/auth/linkedin_auth.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Strona callbacku po logowaniu LinkedIn (OpenID Connect).
/// Odbierana pod /auth/linkedin-callback?code=...&state=...
/// Wymienia kod na Firebase custom token przez Cloud Function i przekierowuje.
class LinkedInCallbackPage extends ConsumerStatefulWidget {
  const LinkedInCallbackPage({
    super.key,
    required this.code,
    required this.state,
    this.error,
  });

  final String? code;
  final String? state;
  final String? error;

  @override
  ConsumerState<LinkedInCallbackPage> createState() => _LinkedInCallbackPageState();
}

class _LinkedInCallbackPageState extends ConsumerState<LinkedInCallbackPage> {
  String? _message;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.error != null) {
      _message = 'LinkedIn zwrócił błąd: ${widget.error}';
      _done = true;
      return;
    }
    if (widget.code == null || widget.code!.isEmpty) {
      _message = 'Brak kodu autoryzacji. Spróbuj zalogować się ponownie.';
      _done = true;
      return;
    }
    if (widget.state == null || widget.state!.isEmpty) {
      _message = 'Brak parametru state. Spróbuj zalogować się ponownie.';
      _done = true;
      return;
    }
    if (!kIsWeb) {
      _message = 'Logowanie przez LinkedIn jest dostępne tylko w przeglądarce.';
      _done = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _exchangeAndSignIn());
  }

  Future<void> _exchangeAndSignIn() async {
    if (!mounted) return;
    final savedState = getLinkedInSavedState();
    if (savedState == null || savedState != widget.state) {
      setState(() {
        _message = 'Nieprawidłowy lub wygasły state. Spróbuj zalogować się ponownie.';
        _done = true;
      });
      return;
    }
    clearLinkedInSavedState();

    String? returnTo;
    parseLinkedInState(widget.state!, (_, r) => returnTo = r);

    final redirectUri = Uri.base.origin + AppConfig.linkedInRedirectPath;
    final exchangeUrl = AppConfig.linkedInExchangeCodeUrl;
    if (exchangeUrl.isEmpty) {
      setState(() {
        _message = 'Brak konfiguracji LinkedIn (linkedinExchangeCodeUrl).';
        _done = true;
      });
      return;
    }

    setState(() => _message = 'Logowanie...');

    try {
      final res = await http.post(
        Uri.parse(exchangeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': widget.code,
          'redirect_uri': redirectUri,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final customToken = body?['customToken'] as String?;
      final errorMsg = body?['error'] as String?;

      if (res.statusCode != 200 || customToken == null) {
        setState(() {
          _message = errorMsg ?? 'Błąd wymiany kodu (${res.statusCode}).';
          _done = true;
        });
        return;
      }

      final auth = ref.read(authServiceProvider);
      final cred = await auth.signInWithLinkedInCustomToken(customToken);
      final user = cred?.user;

      if (!mounted) return;
      if (user == null) {
        setState(() {
          _message = 'Logowanie nie powiodło się.';
          _done = true;
        });
        return;
      }

      final appUser = await auth.getAppUser(user.uid, user);
      if (!mounted) return;

      final target = returnTo ?? AppRouter.dashboard;
      if (appUser?.hasIdentityVerifiedAccess == true || appUser?.ndaAcceptedAt != null) {
        if (kIsWeb) {
          replaceToPath(target);
          return;
        }
        context.go(target);
      } else {
        final rejestracjaUrl = '${AppRouter.rejestracjaDokoncz}?returnTo=${Uri.encodeComponent(target)}';
        if (kIsWeb) {
          replaceToPath(rejestracjaUrl);
          return;
        }
        context.go(rejestracjaUrl);
      }
      setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Wystąpił błąd: $e';
          _done = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_message != null)
                  Text(
                    _message!,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                if (!_done && (_message == null || _message == 'Logowanie...'))
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                if (_done) ...[
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => context.go(AppRouter.logowanie),
                    child: const Text('Wróć do logowania'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
