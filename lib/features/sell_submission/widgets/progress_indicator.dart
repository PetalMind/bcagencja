import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  /// Skrócone etykiety na mobile (np. „Podst.” zamiast „Podstawy”).
  final List<String>? stepLabelsShort;
  /// Callback po kliknięciu w krok (ukończony lub bieżący). Null = kroki nieklikalne.
  final ValueChanged<int>? onStepTapped;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.stepLabelsShort,
    this.onStepTapped,
  });

  static const double _circleSize = 40;
  static const double _circleSizeCurrent = 44;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final label = stepLabels[currentStep];
    return Semantics(
      label: 'Krok ${currentStep + 1} z $totalSteps, $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: Center(
                child: Text(
                  '${currentStep + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Krok ${currentStep + 1} z $totalSteps: $label',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final shortLabels = stepLabelsShort ?? stepLabels;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == totalSteps - 1;
          final canTap = onStepTapped != null && (isCompleted || isCurrent);
          final label = shortLabels[index];

          final stepWidget = Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepCircle(
                      index: index,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isCurrent ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.accent : AppColors.grey200,
                  ),
                ),
            ],
          );

          return Expanded(
            child: Semantics(
              label: 'Krok ${index + 1} z $totalSteps, $label${isCompleted ? ', ukończony' : isCurrent ? ', bieżący' : ''}',
              button: canTap,
              child: canTap
                  ? InkWell(
                      onTap: () => onStepTapped!(index),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: stepWidget,
                    )
                  : stepWidget,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepCircle({
    required int index,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final size = isCurrent ? _circleSizeCurrent : _circleSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent ? AppColors.accent : AppColors.grey200,
        border: isCurrent
            ? Border.all(color: AppColors.accent, width: 3)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: AppColors.white, size: 20)
            : Text(
                '${index + 1}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isCurrent ? AppColors.white : AppColors.grey600,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
