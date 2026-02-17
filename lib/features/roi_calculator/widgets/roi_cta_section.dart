import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sekcja CTA z benchmarkiem i przyciskami w zależności od poziomu ROI.
class RoiCtaSection extends StatelessWidget {
  const RoiCtaSection({
    super.key,
    required this.roi,
    required this.onShowOffers,
    this.onSaveToEmail,
  });

  final double roi;
  final VoidCallback onShowOffers;
  /// Wywołane po naciśnięciu „Zapisz kalkulację na email” – rodzic otwiera modal z danymi.
  final VoidCallback? onSaveToEmail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCtaHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildBenchmark(),
            const SizedBox(height: AppSpacing.lg),
            _buildCtaButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaHeader() {
    if (roi >= 8) {
      return _CtaHeader(
        icon: Icons.celebration,
        title: 'Świetny wynik!',
        message: 'Twoje ROI (${roi.toStringAsFixed(1)}%) jest konkurencyjne. '
            'Mamy nieruchomości o podobnych parametrach – już dostępne!',
      );
    }
    if (roi >= 5) {
      return _CtaHeader(
        icon: Icons.lightbulb_outline,
        title: 'Możesz lepiej!',
        message: 'Twoje ROI (${roi.toStringAsFixed(1)}%) jest akceptowalne, '
            'ale mamy oferty z ROI 9–12% w tym samym przedziale cenowym.',
      );
    }
    return _CtaHeader(
      icon: Icons.warning_amber_outlined,
      title: 'Uwaga – niskie ROI',
      message: 'Twoje ROI (${roi.toStringAsFixed(1)}%) jest poniżej lokat bankowych. '
          'Ta inwestycja może nie mieć sensu ekonomicznego.',
    );
  }

  Widget _buildBenchmark() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benchmark rynkowy:',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          _BenchmarkRow('Lokata bankowa', '5.5%'),
          _BenchmarkRow('Obligacje skarbowe', '6.0%'),
          _BenchmarkRow('Średnie ROI najmu komercyjnego', '8.5%'),
          _BenchmarkRow('Najlepsze oferty na platformie', '9–12%'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            roi >= 8
                ? 'Twoja inwestycja jest POWYŻEJ średniej.'
                : roi >= 5
                    ? 'Twoja inwestycja jest PONIŻEJ średniej.'
                    : 'Porównaj z naszymi ofertami – znajdziesz lepsze ROI.',
            style: AppTextStyles.bodySmall.copyWith(
              color: roi >= 8 ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: onShowOffers,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: Text(
            roi >= 8 ? 'Pokaż oferty' : roi >= 5 ? 'Zobacz lepsze oferty' : 'Pokaż wszystkie oferty',
            style: AppTextStyles.buttonMedium.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (onSaveToEmail != null)
          TextButton(
            onPressed: onSaveToEmail,
            child: const Text('Zapisz kalkulację na email'),
          ),
      ],
    );
  }
}

class _CtaHeader extends StatelessWidget {
  const _CtaHeader({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  const _BenchmarkRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
