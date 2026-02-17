import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

class RoiAdvancedSection extends ConsumerStatefulWidget {
  const RoiAdvancedSection({
    super.key,
    required this.onShowOffers,
  });

  final VoidCallback? onShowOffers;

  @override
  ConsumerState<RoiAdvancedSection> createState() => _RoiAdvancedSectionState();
}

class _RoiAdvancedSectionState extends ConsumerState<RoiAdvancedSection> {
  RoiAdvancedInputs _inputs = const RoiAdvancedInputs();
  RoiQuickResults? _quickResults;
  RoiAdvancedResults? _advancedResults;
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
        _quickResults = RoiCalculations.calculateQuick(_inputs);
        _advancedResults = RoiCalculations.calculateAdvanced(_inputs);
      });
    });
  }

  void _updateInputs(RoiAdvancedInputs Function(RoiAdvancedInputs) fn) {
    setState(() {
      _inputs = fn(_inputs);
      _recalculate();
    });
  }

  String _buildOffersPath() {
    final roi = _quickResults?.roi ?? 0;
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
    if (_quickResults == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => RoiSaveToEmailModal(
        inputs: _inputs,
        results: _quickResults!,
        advancedInputs: _inputs,
        advancedResults: _advancedResults,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildForm(),
              ),
              if (!isMobile) const SizedBox(width: AppSpacing.xl),
              if (!isMobile)
                Expanded(
                  flex: 1,
                  child: _buildResults(),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildResults(),
          ],
        ],
      ),
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
              'PARAMETRY PODSTAWOWE',
              style: AppTextStyles.overline.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Cena zakupu',
              child: _buildCurrencyField(
                _inputs.purchasePrice,
                (v) => _updateInputs((i) => i.copyWithAdvanced(purchasePrice: v)),
                100000,
                50000000,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Roczny przychód z najmu',
              child: _buildCurrencyField(
                _inputs.annualRent,
                (v) => _updateInputs((i) => i.copyWithAdvanced(annualRent: v)),
                0,
                5000000,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Koszty operacyjne (rocznie)',
              child: _buildCurrencyField(
                _inputs.operatingCosts,
                (v) => _updateInputs((i) => i.copyWithAdvanced(operatingCosts: v)),
                0,
                5000000,
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
                onSelectionChanged: (s) => _updateInputs((i) => i.copyWithAdvanced(financing: s.first)),
              ),
            ),
            if (_inputs.financing == FinancingType.credit) ...[
              const SizedBox(height: AppSpacing.md),
              RoiInputField(
                label: 'Wkład własny (%)',
                child: Slider(
                  value: _inputs.downPaymentPercent.clamp(10.0, 80.0),
                  min: 10,
                  max: 80,
                  divisions: 14,
                  onChanged: (v) => _updateInputs((i) => i.copyWithAdvanced(downPaymentPercent: v)),
                ),
              ),
              RoiInputField(
                label: 'Oprocentowanie kredytu',
                tooltip: 'Aktualne WIBOR 6M: ~5.5%',
                child: Slider(
                  value: _inputs.interestRate.clamp(2.0, 15.0),
                  min: 2,
                  max: 15,
                  divisions: 26,
                  onChanged: (v) => _updateInputs((i) => i.copyWithAdvanced(interestRate: v)),
                ),
              ),
              RoiInputField(
                label: 'Okres kredytowania (lata)',
                child: Slider(
                  value: _inputs.loanTermYears.toDouble().clamp(5, 30),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  onChanged: (v) => _updateInputs((i) => i.copyWithAdvanced(loanTermYears: v.round())),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'DODATKOWE PARAMETRY',
              style: AppTextStyles.overline.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Koszty nabycia (notariusz, podatek)',
              tooltip: 'Zazwyczaj 3–5% ceny zakupu',
              child: _buildCurrencyField(
                _inputs.acquisitionCosts,
                (v) => _updateInputs((i) => i.copyWithAdvanced(acquisitionCosts: v)),
                0,
                2000000,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Pustostan/remont (jednorazowo)',
              child: _buildCurrencyField(
                _inputs.vacancyRenovation,
                (v) => _updateInputs((i) => i.copyWithAdvanced(vacancyRenovation: v)),
                0,
                5000000,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Wzrost wartości nieruchomości (rok)',
              tooltip: 'Konserwatywnie: 2–4%',
              child: _buildPercentSlider(
                _inputs.propertyValueGrowthPercent,
                0,
                10,
                (v) => _updateInputs((i) => i.copyWithAdvanced(propertyValueGrowthPercent: v)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Prognoza wzrostu czynszu (rok)',
              tooltip: 'Zazwyczaj indeksacja CPI',
              child: _buildPercentSlider(
                _inputs.rentGrowthPercent,
                0,
                10,
                (v) => _updateInputs((i) => i.copyWithAdvanced(rentGrowthPercent: v)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Horyzont inwestycji',
              child: Slider(
                value: _inputs.investmentHorizonYears.toDouble().clamp(5, 25),
                min: 5,
                max: 25,
                divisions: 4,
                label: '${_inputs.investmentHorizonYears} lat',
                onChanged: (v) => _updateInputs((i) => i.copyWithAdvanced(investmentHorizonYears: v.round())),
              ),
            ),
            Text('${_inputs.investmentHorizonYears} lat', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.lg),
            RoiInputField(
              label: 'Forma opodatkowania',
              child: Column(
                children: [
                  RadioListTile<TaxForm>(
                    title: const Text('Ryczałt 8.5% (najem prywatny)'),
                    value: TaxForm.ryczalt85,
                    groupValue: _inputs.taxForm,
                    onChanged: (v) => v != null ? _updateInputs((i) => i.copyWithAdvanced(taxForm: v)) : null,
                  ),
                  RadioListTile<TaxForm>(
                    title: const Text('Ryczałt 12.5% (najem komercyjny)'),
                    value: TaxForm.ryczalt125,
                    groupValue: _inputs.taxForm,
                    onChanged: (v) => v != null ? _updateInputs((i) => i.copyWithAdvanced(taxForm: v)) : null,
                  ),
                  RadioListTile<TaxForm>(
                    title: const Text('Skala podatkowa (17%/32%)'),
                    value: TaxForm.skala,
                    groupValue: _inputs.taxForm,
                    onChanged: (v) => v != null ? _updateInputs((i) => i.copyWithAdvanced(taxForm: v)) : null,
                  ),
                  RadioListTile<TaxForm>(
                    title: const Text('CIT 9% (mała firma)'),
                    value: TaxForm.cit9,
                    groupValue: _inputs.taxForm,
                    onChanged: (v) => v != null ? _updateInputs((i) => i.copyWithAdvanced(taxForm: v)) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyField(double value, ValueChanged<double> onChanged, double min, double max) {
    return TextFormField(
      key: ValueKey(value.round()),
      initialValue: _currencyFormat.format(value.round()),
      decoration: const InputDecoration(suffixText: 'PLN', border: OutlineInputBorder(), filled: true),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'))],
      onChanged: (s) {
        final v = double.tryParse(s.replaceAll(' ', ''));
        if (v != null) onChanged(v.clamp(min, max));
      },
    );
  }

  Widget _buildPercentSlider(double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round() * 2,
          label: '${value.toStringAsFixed(1)}%',
          onChanged: onChanged,
        ),
        Text('${value.toStringAsFixed(1)}%', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildResults() {
    final adv = _advancedResults;
    final quick = _quickResults;
    if (adv == null || quick == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: AppColors.grey50,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ANALIZA ${_inputs.investmentHorizonYears}-LETNIA',
                  style: AppTextStyles.overline.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('NPV', style: AppTextStyles.caption),
                        Text(
                          '${_currencyFormat.format(adv.npv.round())} PLN',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent),
                        ),
                        Text('(stopa ${(adv.discountRate * 100).toStringAsFixed(0)}%)', style: AppTextStyles.caption),
                      ],
                    ),
                    Column(
                      children: [
                        Text('IRR', style: AppTextStyles.caption),
                        Text(
                          '${adv.irr.toStringAsFixed(1)}%',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 200,
                  child: _buildChart(adv),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildYearTable(adv),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Po ${_inputs.investmentHorizonYears} latach:', style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      _DetailRow('Skumulowany zysk', '${_currencyFormat.format(adv.cumulativeProfit.round())} PLN'),
                      _DetailRow('Wartość nieruchomości', '${_currencyFormat.format(adv.finalPropertyValue.round())} PLN'),
                      _DetailRow('Całkowity zwrot', '${_currencyFormat.format(adv.totalReturn.round())} PLN'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        RoiCtaSection(
          roi: quick.roi,
          onShowOffers: _handleShowOffers,
          onSaveToEmail: _handleSaveToEmail,
        ),
      ],
    );
  }

  Widget _buildChart(RoiAdvancedResults adv) {
    double cumulative = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < adv.yearRows.length; i++) {
      cumulative += adv.yearRows[i].netProfit;
      spots.add(FlSpot((i + 1).toDouble(), cumulative / 1000));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}k'))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('Rok ${v.toInt()}'))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.2)),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildYearTable(RoiAdvancedResults adv) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.grey100),
        columns: const [
          DataColumn(label: Text('Rok')),
          DataColumn(label: Text('Czynsz')),
          DataColumn(label: Text('Koszty')),
          DataColumn(label: Text('Zysk netto')),
        ],
        rows: adv.yearRows.take(10).map((r) {
          return DataRow(
            cells: [
              DataCell(Text('${r.year}')),
              DataCell(Text(_currencyFormat.format(r.rent.round()))),
              DataCell(Text(_currencyFormat.format(r.costs.round()))),
              DataCell(Text(_currencyFormat.format(r.netProfit.round()))),
            ],
          );
        }).toList(),
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
      padding: const EdgeInsets.only(bottom: 4),
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
