import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/wl_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/mobile_menu.dart';
import 'nip_registration_provider.dart';

/// Krok 1 rejestracji NIP: weryfikacja NIP w rejestrze WL, podgląd danych firmy.
class RegistrationNipStepPage extends ConsumerStatefulWidget {
  const RegistrationNipStepPage({super.key});

  @override
  ConsumerState<RegistrationNipStepPage> createState() =>
      _RegistrationNipStepPageState();
}

class _RegistrationNipStepPageState extends ConsumerState<RegistrationNipStepPage> {
  final _nipController = TextEditingController();
  final _wlClient = WlApiClient();

  bool _nipLoading = false;
  String? _nipError;
  WlSubject? _subject;

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
        _subject = null;
      });
      return;
    }
    setState(() {
      _nipError = null;
      _subject = null;
      _nipLoading = true;
    });
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final subject = await _wlClient.searchByNip(nip, date: date);
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _subject = subject;
        if (subject == null) {
          _nipError =
              'Firma o tym NIP jest wykreślona z rejestru VAT lub NIP nie istnieje. '
              'Skontaktuj się: ${AppConfig.contactEmail}';
        } else {
          ref.read(verifiedNipSubjectProvider.notifier).state = subject;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nipLoading = false;
        _subject = null;
        _nipError =
            'Błąd połączenia z rejestrem. Spróbuj później lub skontaktuj się: ${AppConfig.contactEmail}';
      });
    }
  }

  void _goToDetails() {
    final subjectToUse = ref.read(verifiedNipSubjectProvider) ?? _subject;
    if (subjectToUse == null) return;
    ref.read(verifiedNipSubjectProvider.notifier).state = subjectToUse;
    context.go(AppRouter.rejestracjaNipDane);
  }

  void _clearAndEnterNewNip() {
    ref.read(verifiedNipSubjectProvider.notifier).state = null;
    ref.read(nipRegistrationFormProvider.notifier).state = null;
    setState(() {
      _subject = null;
      _nipError = null;
      _nipController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectFromProvider = ref.watch(verifiedNipSubjectProvider);
    final displaySubject = subjectFromProvider ?? _subject;
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Rejestracja firmowa (NIP)',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Krok 1 z 3 – zweryfikuj NIP firmy w rejestrze WL.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'NIP firmy',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nipController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: 'np. 1234567890',
                          errorText: _nipError,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {
                          _nipError = null;
                          _subject = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _nipLoading ? null : _verifyNip,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: _nipLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Weryfikuj NIP'),
                    ),
                  ],
                ),

                if (displaySubject != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: AppColors.success, size: 22),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Firma zweryfikowana: ${displaySubject.name}',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (displaySubject.regon != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'REGON: ${displaySubject.regon}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (displaySubject.statusVat != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Status VAT: ${displaySubject.statusVat}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (displaySubject.residenceAddress != null ||
                            displaySubject.workingAddress != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            displaySubject.residenceAddress ??
                                displaySubject.workingAddress ??
                                '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _goToDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: const Text('Dalej – dane kontaktowe'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _clearAndEnterNewNip,
                    child: Text(
                      'Wpisz inny NIP',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
