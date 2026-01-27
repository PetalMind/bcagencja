import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PriceRangeSlider extends StatefulWidget {
  final double min;
  final double max;
  final Function(double, double) onChanged;
  final double minLimit;
  final double maxLimit;
  
  const PriceRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.onChanged,
    this.minLimit = 0,
    this.maxLimit = 2000000,
  });

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  late RangeValues _currentRange;
  
  @override
  void initState() {
    super.initState();
    _currentRange = RangeValues(widget.min, widget.max);
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatPrice(_currentRange.start)} zł',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_formatPrice(_currentRange.end)} zł',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        RangeSlider(
          values: _currentRange,
          min: widget.minLimit,
          max: widget.maxLimit,
          divisions: 100,
          activeColor: AppColors.accent,
          onChanged: (RangeValues values) {
            setState(() {
              _currentRange = values;
            });
          },
          onChangeEnd: (RangeValues values) {
            widget.onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}
