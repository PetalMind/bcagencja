import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/dashboard_providers.dart';
import '../../../widgets/common/watermarked_image.dart';

/// Sekcja „Wyróżnione oferty” na stronie głównej – karuzela promowanych lub najnowszych ofert.
class HomeFeaturedListings extends ConsumerWidget {
  const HomeFeaturedListings({super.key});

  static const Map<String, String> _propertyTypeLabels = {
    'office': 'Biuro',
    'warehouse': 'Magazyn',
    'retail': 'Handel',
    'industrial': 'Przemysł',
    'hotel': 'Hotel',
    'land': 'Działka',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final featuredAsync = ref.watch(featuredListingsProvider);

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wyróżnione oferty',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRouter.oferty),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Zobacz wszystkie', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(AppIcons.arrowForward, size: 18, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              featuredAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        'Brak ofert do wyświetlenia.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  final cardWidth = isMobile ? 280.0 : 320.0;
                  return SizedBox(
                    height: 340,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: cardWidth,
                          child: _FeaturedCard(
                            property: list[index],
                            propertyTypeLabel: _propertyTypeLabels[list[index].propertyType] ?? list[index].propertyType,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: 340,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) => const SizedBox(width: 320, child: _FeaturedCardShimmer()),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'Nie udało się załadować ofert.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Property property;
  final String propertyTypeLabel;

  const _FeaturedCard({
    required this.property,
    required this.propertyTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.go('/property/${property.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.grey200,
                    child: WatermarkedImage(
                      child: Image.network(
                        property.mainImage ?? (property.images.isNotEmpty ? property.images.first : ''),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          AppIcons.image,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      propertyTypeLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (property.teaserPriceDisplay != null)
                    Text(
                      property.teaserPriceDisplay!,
                      style: AppTextStyles.priceSmall,
                    )
                  else
                    Text(
                      'Zapytaj o cenę',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    property.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(AppIcons.location, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(AppIcons.area, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(
                        '${property.area.toStringAsFixed(0)} m²',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      if (property.roi != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Icon(AppIcons.trending, size: 14, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text(
                          '${property.roi!.toStringAsFixed(1)}% ROI',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCardShimmer extends StatelessWidget {
  const _FeaturedCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 100, color: AppColors.grey200),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 16, width: double.infinity, color: AppColors.grey200),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 14, width: 120, color: AppColors.grey200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
