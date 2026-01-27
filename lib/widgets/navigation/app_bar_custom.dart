import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final List<Widget>? actions;
  
  const AppBarCustom({
    super.key,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: () => context.pop(),
            )
          : isMobile
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(AppIcons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : null,
      title: GestureDetector(
        onTap: () => context.go(AppRouter.home),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BC Agencja',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      actions: actions ??
          [
            if (!isMobile) ...[
              TextButton(
                onPressed: () => context.go(AppRouter.search),
                child: Text(
                  'Szukaj',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRouter.about),
                child: Text(
                  'O nas',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRouter.blog),
                child: Text(
                  'Blog',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRouter.contact),
                child: Text(
                  'Kontakt',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            ElevatedButton(
              onPressed: () => context.go(AppRouter.addListing),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.add, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  if (!isMobile)
                    Text(
                      'Dodaj ogłoszenie',
                      style: AppTextStyles.buttonMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              icon: const Icon(AppIcons.profile),
              onPressed: () => context.go(AppRouter.dashboard),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
    );
  }
}
