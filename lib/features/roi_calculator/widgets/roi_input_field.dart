import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Pole wejściowe z etykietą i opcjonalnym tooltipem (ⓘ)
class RoiInputField extends StatelessWidget {
  const RoiInputField({
    super.key,
    required this.label,
    this.tooltip,
    this.errorText,
    this.warningText,
    required this.child,
  });

  final String label;
  final String? tooltip;
  final String? errorText;
  final String? warningText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: tooltip!,
                triggerMode: TooltipTriggerMode.tap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.help,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Text(
                errorText!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
        if (warningText != null && errorText == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  warningText!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
