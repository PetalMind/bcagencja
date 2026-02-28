import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';

class HomeCategoriesSection extends StatelessWidget {
  const HomeCategoriesSection({super.key});

  static const _categories = [
    _CategoryItem(
      icon: AppIcons.office,
      label: 'Biura',
      propertyType: 'office',
    ),
    _CategoryItem(
      icon: AppIcons.warehouse,
      label: 'Magazyny',
      propertyType: 'warehouse',
    ),
    _CategoryItem(
      icon: AppIcons.retail,
      label: 'Lokale handlowe',
      propertyType: 'retail',
    ),
    _CategoryItem(
      icon: AppIcons.industrial,
      label: 'Przemysł',
      propertyType: 'industrial',
    ),
    _CategoryItem(
      icon: AppIcons.hotel,
      label: 'Hotele',
      propertyType: 'hotel',
    ),
    _CategoryItem(
      icon: AppIcons.land,
      label: 'Grunty',
      propertyType: 'land',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      color: AppColors.grey50,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Szukaj według kategorii',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Przeglądaj oferty w każdym typie nieruchomości',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = isMobile ? 2 : 3;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: isMobile ? 1.4 : 1.5,
                    children: _categories
                        .map((cat) => _CategoryTile(item: cat))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.propertyType,
  });

  final IconData icon;
  final String label;
  final String propertyType;
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({required this.item});

  final _CategoryItem item;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          elevation: _hovered ? 4 : 1,
          shadowColor: AppColors.black.withValues(alpha: _hovered ? 0.12 : 0.06),
          child: InkWell(
            onTap: () => context.go('${AppRouter.oferty}?typ=${item.propertyType}'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            hoverColor: AppColors.accent.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      size: isMobile ? 28 : 36,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                  Text(
                    item.label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
