import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';

/// Obsługa kliknięcia linku weryfikacyjnego z e-maila.
/// Czyta email z query, wywołuje signInWithEmailLink z bieżącym URL i przekierowuje do kroku 2.
class RegistrationEmailLinkHandlerPage extends ConsumerStatefulWidget {
  const RegistrationEmailLinkHandlerPage({
    super.key,
    this.email,
    this.emailLinkOverride,
  });

  /// Email z query (redundantnie z URL).
  final String? email;
  /// Pełny URL z linkiem (na mobile/deep link można przekazać).
  final String? emailLinkOverride;

  @override
  ConsumerState<RegistrationEmailLinkHandlerPage> createState() =>
      _RegistrationEmailLinkHandlerPageState();
}

class _RegistrationEmailLinkHandlerPageState
    extends ConsumerState<RegistrationEmailLinkHandlerPage> {
  String? _error;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLink());
  }

  Future<void> _handleLink() async {
    if (_handled) return;
    final email = widget.email ?? Uri.base.queryParameters['email'];
    if (email == null || email.isEmpty) {
      setState(() {
        _error = 'Brak adresu e-mail w linku. Rozpocznij rejestrację od nowa.';
        _handled = true;
      });
      return;
    }

    final link = widget.emailLinkOverride ?? (kIsWeb ? Uri.base.toString() : null);
    if (link == null || link.isEmpty) {
      setState(() {
        _error = 'Nie można odczytać linku. Otwórz link w tej samej przeglądarce.';
        _handled = true;
      });
      return;
    }

    try {
      await ref.read(authServiceProvider).signInWithEmailLink(
            email: email,
            emailLink: link,
          );
      if (!mounted) return;
      _handled = true;
      context.go(AppRouter.rejestracjaDane);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('expired') || e.toString().contains('invalid')
            ? 'Link wygasł lub został już użyty. Wyślij nowy link weryfikacyjny.'
            : 'Weryfikacja nie powiodła się. Spróbuj ponownie.';
        _handled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null) ...[
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go(AppRouter.rejestracja),
                  child: const Text('Wróć do rejestracji'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Weryfikacja e-maila…',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
