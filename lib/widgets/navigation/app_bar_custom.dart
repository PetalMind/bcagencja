import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/custom_button.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  /// Gdy ustawiony, wyświetlany zamiast "BC Agencja" (np. tytuł podstrony dashboardu).
  final String? title;
  /// Gdy ustawiony przy showBackButton, wywoływany zamiast context.pop() (np. powrót do dashboardu).
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  
  const AppBarCustom({
    super.key,
    this.showBackButton = false,
    this.title,
    this.onBackPressed,
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
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : isMobile
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(AppIcons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : null,
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.white,
              ),
            )
          : GestureDetector(
              onTap: () => context.go(AppRouter.home),
              child: Text(
                'BC Agencja',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.white,
                ),
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
            if (isMobile)
              IconButton(
                icon: const Icon(AppIcons.add),
                onPressed: () => context.go(AppRouter.addListing),
                tooltip: 'Dodaj ogłoszenie',
              )
            else
              CustomButton(
                label: 'Dodaj ogłoszenie',
                icon: AppIcons.add,
                variant: ButtonVariant.gradient,
                size: ButtonSize.medium,
                onPressed: () => context.go(AppRouter.addListing),
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
