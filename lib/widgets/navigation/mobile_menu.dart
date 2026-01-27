import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

class MobileMenu extends StatelessWidget {
  const MobileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.primaryDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _buildMenuItem(
                    context,
                    icon: AppIcons.home,
                    title: 'Strona główna',
                    onTap: () {
                      context.go(AppRouter.home);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.search,
                    title: 'Wyszukiwarka',
                    onTap: () {
                      context.go(AppRouter.search);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.apartment,
                    title: 'Oferty',
                    onTap: () {
                      context.go(AppRouter.searchResults);
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.add,
                    title: 'Dodaj ogłoszenie',
                    onTap: () {
                      context.go(AppRouter.addListing);
                      Navigator.of(context).pop();
                    },
                    highlighted: true,
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.profile,
                    title: 'Panel użytkownika',
                    onTap: () {
                      context.go(AppRouter.dashboard);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.favorites,
                    title: 'Ulubione',
                    onTap: () {
                      context.go(AppRouter.dashboardFavorites);
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.info,
                    title: 'O nas',
                    onTap: () {
                      context.go(AppRouter.about);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.article_rounded,
                    title: 'Blog',
                    onTap: () {
                      context.go(AppRouter.blog);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.email,
                    title: 'Kontakt',
                    onTap: () {
                      context.go(AppRouter.contact);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: highlighted ? AppColors.accent : AppColors.grey600,
        size: AppSpacing.iconMd,
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: highlighted ? AppColors.accent : AppColors.textPrimary,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: highlighted ? AppColors.accent.withOpacity(0.05) : null,
    );
  }
}
