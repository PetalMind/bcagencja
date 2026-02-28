import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/nda_modal.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';
import 'nip_registration_provider.dart';

/// Krok 3 rejestracji NIP: akceptacja regulaminu i NDA, rejestracja konta.
class RegistrationNipTermsStepPage extends ConsumerStatefulWidget {
  const RegistrationNipTermsStepPage({super.key});

  @override
  ConsumerState<RegistrationNipTermsStepPage> createState() =>
      _RegistrationNipTermsStepPageState();
}

class _RegistrationNipTermsStepPageState
    extends ConsumerState<RegistrationNipTermsStepPage> {
  bool _ndaAccepted = false;
  bool _ndaScrolledToEnd = false;
  bool _submitLoading = false;
  String? _submitError;

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
    if (!_ndaAccepted) {
      setState(() => _submitError = 'Wymagana akceptacja Regulaminu i NDA.');
      return;
    }

    final subject = ref.read(verifiedNipSubjectProvider);
    final form = ref.read(nipRegistrationFormProvider);
    if (subject == null || form == null) {
      setState(() => _submitError =
          'Brak danych z poprzednich kroków. Rozpocznij rejestrację od nowa.');
      return;
    }

    setState(() {
      _submitError = null;
      _submitLoading = true;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (kIsWeb) {
        await auth.setPersistence(
          form.stayLoggedIn ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      await auth.registerWithNip(
        email: form.email,
        password: form.password,
        displayName: form.displayName,
        position: form.position,
        phone: form.phone,
        nip: subject.nip,
        companyName: subject.name,
        companyAddress:
            subject.residenceAddress ?? subject.workingAddress ?? '',
        ndaAccepted: true,
        ndaScrolledToEnd: _ndaScrolledToEnd,
        companyRegon: subject.regon,
        companyStatusVat: subject.statusVat,
        companyResidenceAddress: subject.residenceAddress,
        companyWorkingAddress: subject.workingAddress,
      );

      if (!mounted) return;
      ref.read(verifiedNipSubjectProvider.notifier).state = null;
      ref.read(nipRegistrationFormProvider.notifier).state = null;

      // Daj czas na zaktualizowanie stanu auth (StreamProvider), żeby router nie przekierował na logowanie.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      AppRouter.authRefreshNotifier.value++;
      context.go(AppRouter.dashboard);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[NipTerms] registerWithNip error: $e');
        // ignore: avoid_print
        print('[NipTerms] stackTrace: $st');
      }
      if (!mounted) return;
      String msg = 'Nie udało się utworzyć konta. Spróbuj ponownie.';
      final errStr = e.toString().toLowerCase();
      final code = e is FirebaseAuthException
          ? e.code
          : (e is FirebaseException ? e.code : null);
      final codeLower = code?.toLowerCase() ?? '';

      if (errStr.contains('email-already-in-use') || codeLower == 'email-already-in-use') {
        msg = 'Ten adres e-mail jest już zarejestrowany.';
      } else if (errStr.contains('weak-password') || codeLower == 'weak-password') {
        msg =
            'Hasło nie spełnia wymagań (wielka/mała litera, cyfra, znak specjalny, min. 8 znaków).';
      } else if (errStr.contains('permission-denied') ||
          errStr.contains('insufficient permissions') ||
          codeLower == 'permission-denied') {
        msg = 'Błąd uprawnień (spróbuj odświeżyć stronę i zarejestrować się ponownie).';
      } else if (errStr.contains('network') || codeLower == 'unavailable') {
        msg = 'Błąd sieci. Sprawdź połączenie i spróbuj ponownie.';
      }
      setState(() {
        _submitError = msg;
        _submitLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = ref.watch(verifiedNipSubjectProvider);
    final form = ref.watch(nipRegistrationFormProvider);
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (subject == null || form == null) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Regulamin i NDA',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Krok 3 z 3 – zaakceptuj regulamin i NDA, aby założyć konto firmowe.',
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

                Text(
                  'Regulamin i NDA',
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
                        onChanged: (v) =>
                            setState(() => _ndaAccepted = v ?? false),
                        activeColor: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akceptuję Regulamin, Politykę Prywatności i NDA*',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    context.push(AppRouter.politykaPrywatnosci),
                                child: Text(
                                  'Polityka Prywatności',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                ' • ',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
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

                FilledButton(
                  onPressed: _submitLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
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

                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Administratorem danych osobowych jest ${AppConfig.dataControllerName}. '
                      'Twoje dane będą przetwarzane w celu świadczenia usług platformy. '
                      'Przysługuje Ci prawo dostępu, sprostowania i usunięcia danych. ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRouter.politykaPrywatnosci),
                      child: Text(
                        'Polityka Prywatności',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go(AppRouter.rejestracjaNipDane),
                  child: Text(
                    'Wróć do danych kontaktowych',
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
    );
  }
}
