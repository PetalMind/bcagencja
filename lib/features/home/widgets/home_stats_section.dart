import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Sekcja statystyk / social proof na stronie głównej (ciemne tło).
class HomeStatsSection extends StatelessWidget {
  const HomeStatsSection({super.key});

  static const List<_StatItem> _stats = [
    _StatItem(value: '500+', label: 'Zweryfikowanych inwestorów'),
    _StatItem(value: '127', label: 'Sprzedanych nieruchomości'),
    _StatItem(value: '48h', label: 'Czas bezpłatnej wyceny'),
    _StatItem(value: '100%', label: 'Dyskrecja i NDA'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.xl : AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: isMobile ? _buildMobile(context) : _buildDesktop(context),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _stats.map((stat) => Expanded(child: _StatTile(item: stat))).toList(),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      children: _stats
          .map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _StatTile(item: stat),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.value,
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          item.label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
