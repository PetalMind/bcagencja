import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/app_user.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/nda_modal.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';

/// Krok 3 rejestracji e-mail: akceptacja regulaminu i NDA.
class RegistrationTermsStepPage extends ConsumerStatefulWidget {
  const RegistrationTermsStepPage({super.key});

  @override
  ConsumerState<RegistrationTermsStepPage> createState() =>
      _RegistrationTermsStepPageState();
}

class _RegistrationTermsStepPageState
    extends ConsumerState<RegistrationTermsStepPage> {
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
    setState(() {
      _submitError = null;
      _submitLoading = true;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final userId = ref.read(currentUserProvider).asData?.value?.id;
      await auth.acceptNdaAndGrantLevel2(accountType: AccountType.person);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[RegistrationTerms] acceptNdaAndGrantLevel2 OK');
      }
      if (userId != null) {
        unawaited(
          auth.logNdaAcceptance(
            userId: userId,
            ndaVersion: 'v1.0',
            scrolledToEnd: _ndaScrolledToEnd,
          ).catchError((Object e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('[RegistrationTerms] logNdaAcceptance error: $e');
            }
          }),
        );
      }
      if (!mounted) return;
      context.go(AppRouter.dashboard);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[RegistrationTerms] submit error: $e $st');
      }
      if (mounted) {
        setState(() {
          _submitError = 'Nie udało się dokończyć rejestracji. Spróbuj ponownie.';
          _submitLoading = false;
        });
      }
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
                  'Krok 3 z 3 – zaakceptuj regulamin i umowę NDA, aby uzyskać dostęp do ofert.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

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
                      : const Text('Zakończ rejestrację'),
                ),
                const SizedBox(height: AppSpacing.xl),

                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Administratorem danych osobowych jest BC Agencja. '
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
