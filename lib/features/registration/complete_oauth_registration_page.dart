import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/app_user.dart';
import '../../core/config/app_config.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/nda_modal.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/mobile_menu.dart';

void _oauthRegLog(String message, [Object? detail]) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('[OAuthReg] $message${detail != null ? ' $detail' : ''}');
  }
}

/// Preferowane typy inwestycji (multi-select).
const List<String> preferredInvestmentTypesOptions = [
  'Grunty komercyjne',
  'Obiekty handlowe',
  'Biura',
  'Magazyny',
  'Nieruchomości z najemcą',
];

/// Ekran "Dokończ rejestrację" po powrocie z OAuth (Google/Apple/LinkedIn).
/// Osoba fizyczna vs firma, NDA, opcjonalnie: preferowany typ, budżet.
class CompleteOAuthRegistrationPage extends ConsumerStatefulWidget {
  const CompleteOAuthRegistrationPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<CompleteOAuthRegistrationPage> createState() =>
      _CompleteOAuthRegistrationPageState();
}

class _CompleteOAuthRegistrationPageState
    extends ConsumerState<CompleteOAuthRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  AccountType _accountType = AccountType.person;
  final _companyNameController = TextEditingController();
  final _nipController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _ndaAccepted = false;
  bool _ndaScrolledToEnd = false;
  final Set<String> _preferredTypes = {};
  double _budgetMin = 500000;
  double _budgetMax = 2000000;
  bool _submitLoading = false;
  String? _submitError;

  @override
  void dispose() {
    _companyNameController.dispose();
    _nipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
    _oauthRegLog('_submit start');
    if (!_ndaAccepted) {
      setState(() => _submitError = 'Wymagana akceptacja Regulaminu i NDA.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _oauthRegLog('_submit: walidacja nie przeszła');
      return;
    }
    setState(() {
      _submitError = null;
      _submitLoading = true;
    });
    try {
      _oauthRegLog('_submit: wywołanie completeOAuthRegistration');
      final auth = ref.read(authServiceProvider);
      await auth.completeOAuthRegistration(
        accountType: _accountType,
        companyName:
            _accountType == AccountType.company
                ? _companyNameController.text.trim()
                : null,
        nip:
            _accountType == AccountType.company &&
                    _nipController.text.trim().isNotEmpty
                ? _nipController.text.trim()
                : null,
        ndaAccepted: true,
        ndaScrolledToEnd: _ndaScrolledToEnd,
        phone: _phoneController.text.trim().isNotEmpty
            ? '+48 ${_phoneController.text.trim()}'
            : null,
        preferredInvestmentTypes:
            _preferredTypes.isEmpty ? null : _preferredTypes.toList(),
        budgetMin: _preferredTypes.isNotEmpty ? _budgetMin.round() : null,
        budgetMax: _preferredTypes.isNotEmpty ? _budgetMax.round() : null,
      );
      _oauthRegLog('_submit: completeOAuthRegistration zakończone');
      if (!mounted) {
        _oauthRegLog('_submit: unmounted po completeOAuthRegistration');
        return;
      }
      final target = widget.returnTo != null && widget.returnTo!.isNotEmpty
          ? widget.returnTo!
          : AppRouter.dashboard;
      _oauthRegLog('_submit: context.go', target);
      setState(() => _submitLoading = false);
      context.go(target);
    } catch (e, st) {
      _oauthRegLog('_submit: błąd', e);
      if (kDebugMode) {
        // ignore: avoid_print
        print(st);
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
    final authState = ref.watch(currentUserProvider);
    final isMobile =
        MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    // Wczytywanie stanu auth (np. po pełnym przeładowaniu strony po OAuth) – czekamy.
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.asData?.value;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRouter.logowanie);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.hasIdentityVerifiedAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = widget.returnTo;
        context.go(
            target != null && target.isNotEmpty ? target : AppRouter.dashboard);
      });
      return Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = user.displayName ?? 'Użytkowniku';

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  'Witaj, $displayName!',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ostatni krok przed dostępem do ofert:',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Osoba fizyczna vs Firma
                Text(
                  'Typ konta',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RadioListTile<AccountType>(
                  value: AccountType.person,
                  groupValue: _accountType,
                  onChanged: (v) => setState(() => _accountType = v!),
                  title: const Text('Jestem osobą fizyczną'),
                  activeColor: AppColors.primaryDark,
                ),
                RadioListTile<AccountType>(
                  value: AccountType.company,
                  groupValue: _accountType,
                  onChanged: (v) => setState(() => _accountType = v!),
                  title: const Text('Reprezentuję firmę'),
                  activeColor: AppColors.primaryDark,
                ),

                if (_accountType == AccountType.company) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _companyNameController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nazwa firmy',
                      hintText: 'ABC Sp. z o.o.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nipController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'NIP',
                      hintText: '1234567890',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Telefon (opcjonalnie)
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
                const SizedBox(height: AppSpacing.lg),

                // NDA
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
                        onChanged: (v) => setState(() => _ndaAccepted = v ?? false),
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

                // Opcjonalnie: preferowany typ inwestycji
                Text(
                  'Preferowany typ inwestycji (opcjonalnie)',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...preferredInvestmentTypesOptions.map((label) {
                  final selected = _preferredTypes.contains(label);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _preferredTypes.add(label);
                        } else {
                          _preferredTypes.remove(label);
                        }
                      });
                    },
                    title: Text(label),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryDark,
                  );
                }),
                const SizedBox(height: AppSpacing.lg),

                // Budżet (opcjonalnie)
                Text(
                  'Budżet inwestycyjny (opcjonalnie) – pomoże dopasować oferty',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RangeSlider(
                  values: RangeValues(_budgetMin, _budgetMax),
                  min: 100000,
                  max: 10000000,
                  divisions: 99,
                  labels: RangeLabels(
                    '${(_budgetMin / 1000).round()}k PLN',
                    '${(_budgetMax / 1000000).toStringAsFixed(1)}M PLN',
                  ),
                  onChanged: (v) =>
                      setState(() {
                        _budgetMin = v.start;
                        _budgetMax = v.end;
                      }),
                  activeColor: AppColors.primaryDark,
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
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                      : const Text('Dokończ rejestrację'),
                ),
                const SizedBox(height: AppSpacing.xl),

                // RODO
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Administratorem danych osobowych jest ${AppConfig.dataControllerName}. '
                      'Twoje dane będą przetwarzane w celu świadczenia usług platformy. '
                      'Przysługuje Ci prawo dostępu, sprostowania i usunięcia danych. ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
      ),
    );
  }
}
