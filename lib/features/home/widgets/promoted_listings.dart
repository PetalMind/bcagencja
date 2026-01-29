import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/shimmer_placeholder.dart';

class PromotedListings extends StatelessWidget {
  const PromotedListings({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    // Mock promoted properties
    final promotedProperties = List.generate(3, (i) => Property.mock(i));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Promowane oferty',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomButton(
                      label: 'Zobacz wszystkie',
                      trailingIcon: Icons.arrow_forward_rounded,
                      variant: ButtonVariant.text,
                      size: ButtonSize.medium,
                      onPressed: () => context.go(AppRouter.searchResults),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promowane oferty',
                      style: AppTextStyles.headlineLarge,
                    ),
                    CustomButton(
                      label: 'Zobacz wszystkie',
                      trailingIcon: Icons.arrow_forward_rounded,
                      variant: ButtonVariant.text,
                      size: ButtonSize.medium,
                      onPressed: () => context.go(AppRouter.searchResults),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: promotedProperties.map((property) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _PromotedCard(property: property),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: promotedProperties.map((property) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _PromotedCard(property: property),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotedCard extends ConsumerStatefulWidget {
  final Property property;

  const _PromotedCard({required this.property});

  @override
  ConsumerState<_PromotedCard> createState() => _PromotedCardState();
}

class _PromotedCardState extends ConsumerState<_PromotedCard> {
  bool _isHovered = false;
  int _currentImageIndex = 0;
  Timer? _carouselTimer;

  static const Duration _carouselInterval = Duration(milliseconds: 2500);

  @override
  void dispose() {
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _onHoverEnter(PointerEvent _) {
    if (!mounted) return;
    setState(() => _isHovered = true);
    if (widget.property.images.length > 1) {
      _carouselTimer?.cancel();
      _carouselTimer = Timer.periodic(_carouselInterval, (_) {
        if (!mounted) return;
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % widget.property.images.length;
        });
      });
    }
  }

  void _onHoverExit(PointerEvent _) {
    if (!mounted) return;
    setState(() => _isHovered = false);
    _carouselTimer?.cancel();
    _carouselTimer = null;
    setState(() => _currentImageIndex = 0);
  }

  double _imageHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < AppSpacing.mobileBreakpoint ? 180 : 220;
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(property.id);
    final imageHeight = _imageHeight(context);

    return MouseRegion(
      onEnter: _onHoverEnter,
      onExit: _onHoverExit,
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: _isHovered ? 0.2 : 0.12),
                blurRadius: _isHovered ? 24 : 16,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: _isHovered ? 0.12 : 0.08),
                blurRadius: _isHovered ? 16 : 12,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/property/${property.id}'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageStack(context, property, imageHeight, isFavorite),
                    _buildContent(property),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageStack(
    BuildContext context,
    Property property,
    double imageHeight,
    bool isFavorite,
  ) {
    final imageUrl = property.images.isNotEmpty
        ? property.images[_currentImageIndex % property.images.length]
        : (property.mainImage ?? '');
    final borderRadius = const BorderRadius.vertical(
      top: Radius.circular(AppSpacing.radiusMd),
    );

    return Stack(
      children: [
        Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: AppColors.grey200,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ShimmerPlaceholder(
                      width: double.infinity,
                      height: imageHeight,
                      borderRadius: borderRadius,
                    ),
                    Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.grey200,
                child: const Icon(
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'PROMOWANE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (property.images.length > 1) ...[
          Positioned(
            bottom: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                property.images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == i
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${property.images.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: IconButton(
            icon: Icon(
              isFavorite ? AppIcons.favorites : AppIcons.favoriteBorder,
              color: isFavorite ? AppColors.accent : AppColors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.black.withValues(alpha: 0.5),
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggle(property.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Property property) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.propertyTypeLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            property.formattedPrice,
            style: AppTextStyles.priceMedium,
          ),
          if (property.pricePerSqm != null) ...[
            const SizedBox(height: 2),
            Text(
              '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            property.title,
            style: AppTextStyles.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                AppIcons.location,
                size: AppSpacing.iconSm,
                color: AppColors.grey600,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  property.location,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildParameter(
                icon: AppIcons.area,
                value: '${property.area.toStringAsFixed(0)} m²',
              ),
              const SizedBox(width: AppSpacing.md),
              _buildParameter(
                icon: AppIcons.floors,
                value: '${property.floors} kond.',
              ),
              if (property.parkingSpaces != null &&
                  property.parkingSpaces! > 0) ...[
                const SizedBox(width: AppSpacing.md),
                _buildParameter(
                  icon: AppIcons.parkingSpaces,
                  value: '${property.parkingSpaces} miejsc',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameter({
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconSm,
          color: AppColors.grey600,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
