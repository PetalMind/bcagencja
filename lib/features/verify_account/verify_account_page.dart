import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/services/wl_api_client.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/custom_button.dart';

/// Ekran weryfikacji konta – Grant Level 2 (Identity Verified).
/// Metody: OAuth LinkedIn (placeholder) LUB walidacja NIP przez API WL (wl-api.mf.gov.pl).
/// Wymaganie: akceptacja regulaminu NDA. Akcja: przypisanie użytkownika do bazy Leads.
/// [returnTo] – ścieżka do przekierowania po weryfikacji (np. /oferty, /property/1).
class VerifyAccountPage extends ConsumerStatefulWidget {
  const VerifyAccountPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends ConsumerState<VerifyAccountPage> {
  final _nipController = TextEditingController();
  final _wlClient = WlApiClient();
  WlSubject? _nipSubject;
  bool _nipLoading = false;
  String? _nipError;
  bool _ndaAccepted = false;
  bool _submitLoading = false;
  String? _submitError;

  @override
  void dispose() {
    _nipController.dispose();
    super.dispose();
  }

  Future<void> _verifyNip() async {
    final nip = _nipController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (nip.length != 10) {
      setState(() {
        _nipError = 'NIP musi mieć 10 cyfr';
        _nipSubject = null;
      });
      return;
    }
    setState(() {
      _nipError = null;
      _nipSubject = null;
      _nipLoading = true;
    });
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final subject = await _wlClient.searchByNip(nip, date: date);
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _nipSubject = subject;
        _nipError = subject == null ? 'Nie znaleziono podmiotu o podanym NIP' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _nipSubject = null;
        _nipError = 'Błąd połączenia z rejestrem. Spróbuj później.';
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_ndaAccepted) return;
    setState(() {
      _submitError = null;
      _submitLoading = true;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final nipStr = _nipController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      await auth.acceptNdaAndGrantLevel2(
        nip: _nipSubject?.nip ?? (nipStr.isNotEmpty ? nipStr : null),
        companyName: _nipSubject?.name,
      );
      if (!mounted) return;
      final target = widget.returnTo;
      context.go(target != null && target.isNotEmpty ? target : AppRouter.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitLoading = false;
        _submitError = 'Nie udało się zapisać weryfikacji. Spróbuj ponownie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRouter.logowanie);
      });
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user.hasIdentityVerifiedAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = widget.returnTo;
        context.go(target != null && target.isNotEmpty ? target : AppRouter.dashboard);
      });
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canSubmit = _ndaAccepted && (_nipSubject != null);

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
                Icon(
                  Icons.verified_user_outlined,
                  size: 48,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Zweryfikuj konto (Level 2)',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aby zobaczyć pełne oferty (lokalizacja, galeria), zweryfikuj tożsamość przez LinkedIn lub NIP z rejestru VAT.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // LinkedIn (placeholder)
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.link, size: 22),
                  label: const Text('Zaloguj przez LinkedIn (wkrótce)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // NIP
                Text(
                  'Weryfikacja NIP (Rejestr WL)',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nipController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'NIP (10 cyfr)',
                          errorText: _nipError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        onChanged: (_) => setState(() {
                          _nipError = null;
                          _nipSubject = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _nipLoading ? null : _verifyNip,
                      child: _nipLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sprawdź NIP'),
                    ),
                  ],
                ),
                if (_nipSubject != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nipSubject!.name,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_nipSubject!.statusVat != null)
                                Text(
                                  'Status VAT: ${_nipSubject!.statusVat}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // NDA
                Text(
                  'Regulamin i NDA',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akceptuję regulamin serwisu oraz warunki umowy NDA (Non-Disclosure Agreement). '
                        'Zobowiązuję się nie ujawniać poufnych informacji dotyczących ofert nieruchomości '
                        'poza celem własnej oceny inwestycyjnej.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        value: _ndaAccepted,
                        onChanged: (v) => setState(() => _ndaAccepted = v ?? false),
                        title: Text(
                          'Akceptuję regulamin i NDA',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_submitError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

                CustomButton(
                  label: 'Potwierdź weryfikację',
                  icon: AppIcons.login,
                  variant: ButtonVariant.gradient,
                  size: ButtonSize.large,
                  fullWidth: true,
                  isLoading: _submitLoading,
                  onPressed: canSubmit && !_submitLoading ? _submitVerification : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
