import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/roi_models.dart';
import '../logic/roi_calculations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'roi_input_field.dart';
import 'roi_cta_section.dart';
import 'roi_registration_modal.dart';
import 'roi_save_to_email_modal.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _currencyFormat = NumberFormat('#,###', 'pl_PL');

class RoiQuickSection extends ConsumerStatefulWidget {
  const RoiQuickSection({
    super.key,
    required this.onShowOffers,
    required this.scenarios,
  });

  final VoidCallback? onShowOffers;
  final List<RoiScenario> scenarios;

  @override
  ConsumerState<RoiQuickSection> createState() => _RoiQuickSectionState();
}

class _RoiQuickSectionState extends ConsumerState<RoiQuickSection> {
  RoiQuickInputs _inputs = const RoiQuickInputs();
  RoiQuickResults? _results;
  Timer? _debounce;
  static const _debounceMs = 300;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _recalculate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      setState(() {
        _results = RoiCalculations.calculateQuick(_inputs);
      });
    });
  }

  void _applyScenario(RoiQuickInputs inputs) {
    setState(() {
      _inputs = inputs;
      _recalculate();
    });
  }

  String _buildOffersPath() {
    final roi = _results?.roi ?? 0;
    final cena = _inputs.purchasePrice;
    final cenaMin = (cena * 0.8).round();
    final cenaMax = (cena * 1.2).round();
    return '${AppRouter.oferty}?roiMin=${roi.toStringAsFixed(1)}&cenaMin=$cenaMin&cenaMax=$cenaMax';
  }

  void _handleShowOffers() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && user.hasIdentityVerifiedAccess) {
      context.go(_buildOffersPath());
      widget.onShowOffers?.call();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => RoiRegistrationModal(returnPath: _buildOffersPath()),
      );
    }
  }

  void _handleSaveToEmail() {
    if (_results == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => RoiSaveToEmailModal(
        inputs: _inputs,
        results: _results!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScenarioButtons(),
                const SizedBox(height: AppSpacing.lg),
                _buildForm(),
                const SizedBox(height: AppSpacing.xl),
                if (_results != null) _buildResults(_results!),
                if (_results != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  RoiCtaSection(
                    roi: _results!.roi,
                    onShowOffers: _handleShowOffers,
                    onSaveToEmail: _handleSaveToEmail,
                  ),
                ],
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScenarioButtons(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildForm(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_results != null) _buildResults(_results!),
                    if (_results != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      RoiCtaSection(
                        roi: _results!.roi,
                        onShowOffers: _handleShowOffers,
                        onSaveToEmail: _handleSaveToEmail,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScenarioButtons() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: widget.scenarios
          .map((s) => FilterChip(
                label: Text(s.label),
                selected: false,
                onSelected: (_) => _applyScenario(s.inputs),
              ))
          .toList(),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PARAMETRY INWESTYCJI',
              style: AppTextStyles.overline.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPriceField(),
            const SizedBox(height: AppSpacing.lg),
            _buildAnnualRentField(),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Koszty operacyjne (rocznie)',
              tooltip: 'Podatki, ubezpieczenie, utrzymanie',
              child: _buildCurrencyTextField(
                value: _inputs.operatingCosts,
                onChanged: (v) {
                  setState(() {
                    _inputs = _inputs.copyWith(operatingCosts: v);
                    _recalculate();
                  });
                },
                min: 0,
                max: 5000000,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Sposób finansowania',
              child: SegmentedButton<FinancingType>(
                segments: const [
                  ButtonSegment(value: FinancingType.cash, label: Text('Gotówka')),
                  ButtonSegment(value: FinancingType.credit, label: Text('Kredyt/Leasing')),
                ],
                selected: {_inputs.financing},
                onSelectionChanged: (s) {
                  setState(() {
                    _inputs = _inputs.copyWith(financing: s.first);
                    _recalculate();
                  });
                },
              ),
            ),
            if (_inputs.financing == FinancingType.credit) ...[
              const SizedBox(height: AppSpacing.lg),
              RoiInputField(
                label: 'Wkład własny (%)',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _inputs.downPaymentPercent.clamp(10.0, 80.0),
                    min: 10,
                    max: 80,
                    divisions: 14,
                    label: '${_inputs.downPaymentPercent.round()}%',
                    onChanged: (v) {
                      setState(() {
                        _inputs = _inputs.copyWith(downPaymentPercent: v);
                        _recalculate();
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${_inputs.downPaymentPercent.round()}%',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              RoiInputField(
                label: 'Oprocentowanie kredytu',
                tooltip: 'Aktualne WIBOR 6M: ~5.5%. WIBOR 6M + marża banku (np. 2%)',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _inputs.interestRate.clamp(2.0, 15.0),
                    min: 2,
                    max: 15,
                    divisions: 26,
                    label: '${_inputs.interestRate.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _inputs = _inputs.copyWith(interestRate: v);
                        _recalculate();
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${_inputs.interestRate.toStringAsFixed(1)}% (WIBOR 6M + marża)',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              RoiInputField(
                label: 'Okres kredytowania',
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _inputs.loanTermYears.toDouble().clamp(5, 30),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    label: '${_inputs.loanTermYears} lat',
                    onChanged: (v) {
                      setState(() {
                        _inputs = _inputs.copyWith(loanTermYears: v.round());
                        _recalculate();
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${_inputs.loanTermYears} lat',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    String? error;
    if (_inputs.purchasePrice < 100000) {
      error = 'Minimalna cena to 100 000 PLN (nieruchomości komercyjne)';
    }
    return RoiInputField(
      label: 'Cena zakupu nieruchomości*',
      errorText: error,
      child: Column(
        children: [
          _buildCurrencyTextField(
            value: _inputs.purchasePrice,
            onChanged: (v) {
              setState(() {
                _inputs = _inputs.copyWith(purchasePrice: v);
                _recalculate();
              });
            },
            min: 100000,
            max: 50000000,
          ),
          const SizedBox(height: AppSpacing.xs),
          Slider(
            value: _inputs.purchasePrice.clamp(100000.0, 50000000.0),
            min: 100000,
            max: 50000000,
            divisions: 499,
            onChanged: (v) {
              setState(() {
                _inputs = _inputs.copyWith(purchasePrice: v);
                _recalculate();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualRentField() {
    return RoiInputField(
      label: 'Roczny przychód z najmu*',
      child: Column(
        children: [
          _buildCurrencyTextField(
            value: _inputs.annualRent,
            onChanged: (v) {
              setState(() {
                _inputs = _inputs.copyWith(annualRent: v);
                _recalculate();
              });
            },
            min: 0,
            max: 5000000,
          ),
          const SizedBox(height: AppSpacing.xs),
          Slider(
            value: _inputs.annualRent.clamp(0.0, 5000000.0),
            min: 0,
            max: 5000000,
            divisions: 500,
            onChanged: (v) {
              setState(() {
                _inputs = _inputs.copyWith(annualRent: v);
                _recalculate();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTextField({
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    final str = _currencyFormat.format(value.round());
    return TextFormField(
      key: ValueKey(value.round()),
      initialValue: str,
      decoration: InputDecoration(
        suffixText: 'PLN',
        border: const OutlineInputBorder(),
        filled: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
      ],
      onChanged: (s) {
        final cleaned = s.replaceAll(' ', '');
        final v = double.tryParse(cleaned);
        if (v != null) {
          final clamped = v.clamp(min, max);
          onChanged(clamped);
        }
      },
    );
  }

  Widget _buildResults(RoiQuickResults r) {
    final isCredit = _inputs.financing == FinancingType.credit;
    final dscrWarning = isCredit && r.dscr < 1.25 && r.dscr != double.infinity;

    return Card(
      color: AppColors.grey50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TWÓJ WYNIK',
              style: AppTextStyles.overline.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResultBox(
              value: '${r.roi.toStringAsFixed(1)}%',
              label: 'ROI',
              sublabel: 'Return on Investment',
            ),
            const SizedBox(height: AppSpacing.md),
            if (isCredit)
              _ResultBox(
                value: '${r.roe.toStringAsFixed(1)}%',
                label: 'ROE',
                sublabel: 'Return on Equity (z kredytem)',
              ),
            if (isCredit) const SizedBox(height: AppSpacing.md),
            Text(
              'Szczegóły:',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow('Kapitał własny', '${_currencyFormat.format(r.equity.round())} PLN'),
            _DetailRow('Miesięczna rata', '${_currencyFormat.format(r.monthlyPayment.round())} PLN'),
            _DetailRow('Zysk netto (rok 1)', '${_currencyFormat.format(r.netProfitYear1.round())} PLN'),
            _DetailRow('Okres zwrotu', '${r.paybackYears.toStringAsFixed(1)} lat'),
            if (isCredit) _DetailRow('DSCR', '${r.dscr.toStringAsFixed(2)} ${r.dscr >= 1.25 ? '✓' : ''}'),
            if (dscrWarning) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'DSCR poniżej 1.25 = trudności z kredytem bankowym',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Możliwe rozwiązania: zwiększ wkład własny do 40%, poszukaj nieruchomości z wyższym czynszem, negocjuj niższe oprocentowanie.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.value,
    required this.label,
    required this.sublabel,
  });

  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.accent)),
          Text(label, style: AppTextStyles.labelMedium),
          Text(sublabel, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
