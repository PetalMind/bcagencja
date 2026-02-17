import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/router/app_router.dart';

/// Sidebar na stronie Zapisane: status inwestora + rekomendacje „Może Cię zainteresować”.
class SavedOffersSidebar extends StatelessWidget {
  const SavedOffersSidebar({
    super.key,
    required this.savedCount,
    this.compareCount = 0,
    this.recommendations = const [],
  });

  final int savedCount;
  final int compareCount;
  final List<Property> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InvestorStatusCard(savedCount: savedCount, compareCount: compareCount),
        const SizedBox(height: AppSpacing.lg),
        if (recommendations.isNotEmpty) _RecommendationsCard(properties: recommendations),
      ],
    );
  }
}

class _InvestorStatusCard extends StatelessWidget {
  const _InvestorStatusCard({required this.savedCount, this.compareCount = 0});

  final int savedCount;
  final int compareCount;

  @override
  Widget build(BuildContext context) {
    const maxForLevel = 50;
    final stars = (savedCount / 10).floor().clamp(0, 5);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.statistics, color: AppColors.accent, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Twój status inwestora',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Zapisane oferty: $savedCount/$maxForLevel ${List.generate(stars, (_) => '⭐').join()}${List.generate(5 - stars, (_) => '⚪').join()}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              'Porównań: $compareCount',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Następny poziom: Expert (50 zapisów)',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.properties});

  final List<Property> properties;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Może Cię zainteresować',
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Na podstawie zapisanych ofert',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...properties.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    onTap: () => context.go('/property/${p.id}'),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${p.formattedPrice} · ${p.roi != null ? '${p.roi!.toStringAsFixed(1)}% ROI' : ''}',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRouter.kalkulatorRoi),
                          child: const Text('Porównaj'),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
