import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../input_formatters.dart';
import '../listing_submission_model.dart';

/// Krok 4: Szacunkowa cena – anchoring, oczekiwana cena, elastyczność.
class Step4Price extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final bool readOnly;

  const Step4Price({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.readOnly = false,
  });

  @override
  State<Step4Price> createState() => _Step4PriceState();
}

class _Step4PriceState extends State<Step4Price> {
  late TextEditingController _expectedPriceController;

  @override
  void initState() {
    super.initState();
    _expectedPriceController = TextEditingController(
      text: widget.formData.expectedPrice != null
          ? widget.formData.expectedPrice!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _expectedPriceController.dispose();
    super.dispose();
  }

  void _syncExpectedPrice() {
    final s = _expectedPriceController.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final v = double.tryParse(s);
    widget.formData.expectedPrice = v != null && v > 0 ? v : null;
    widget.onDataChanged(widget.formData);
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.formData.estimatedRangeFromRent;
    final minVal = widget.formData.estimatedValueMin ?? range?.$1;
    final maxVal = widget.formData.estimatedValueMax ?? range?.$2;
    final hasRange = (minVal != null && maxVal != null) || range != null;
    final displayMin = minVal ?? range?.$1 ?? 0.0;
    final displayMax = maxVal ?? range?.$2 ?? 0.0;
    final avg = hasRange ? (displayMin + displayMax) / 2 : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Za ile chcesz sprzedać?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasRange) ...[
            Text(
              'Na podstawie Twoich danych szacujemy wartość na:',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatPrice(displayMin)} – ${_formatPrice(displayMax)} PLN',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                  ),
                  if (avg != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Średnio dla podobnych: ${_formatPrice(avg)} PLN',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text(
            'Twoja oczekiwana cena:',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _expectedPriceController,
            readOnly: widget.readOnly,
            onChanged: widget.readOnly ? null : (_) => _syncExpectedPrice(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              DecimalTextInputFormatter(maxLength: kMaxPriceLength),
              LengthLimitingTextInputFormatter(kMaxPriceLength),
            ],
            decoration: InputDecoration(
              labelText: 'Oczekiwana cena',
              suffixText: 'PLN',
              hintText: 'np. 2900000',
              helperText: 'Tylko cyfry, bez liter',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Elastyczność co do ceny:',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _radio('flexible', 'Jestem elastyczny/a co do ceny'),
          _radio('minimum', 'To jest moja minimalna cena'),
          _radio('want_valuation', 'Chcę najpierw poznać dokładną wycenę'),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Darmowa wycena przez certyfikowanego rzeczoznawcę w ciągu 48h',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radio(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RadioListTile<String>(
        value: value,
        groupValue: widget.formData.priceFlexibility,
        title: Text(label, style: AppTextStyles.bodyMedium),
        onChanged: widget.readOnly ? null : (v) {
          widget.formData.priceFlexibility = v;
          widget.onDataChanged(widget.formData);
          setState(() {});
        },
      ),
    );
  }

  String _formatPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} tys.';
    return v.toStringAsFixed(0);
  }
}
