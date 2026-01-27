import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

class Sidebar extends StatelessWidget {
  final String? currentRoute;
  
  const Sidebar({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primaryDark,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      AppIcons.profile,
                      size: 32,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Panel użytkownika',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: AppIcons.apartment,
                  title: 'Moje ogłoszenia',
                  route: AppRouter.dashboardListings,
                ),
                _buildMenuItem(
                  context,
                  icon: AppIcons.favorites,
                  title: 'Ulubione',
                  route: AppRouter.dashboardFavorites,
                ),
                _buildMenuItem(
                  context,
                  icon: AppIcons.notifications,
                  title: 'Zapisane wyszukiwania',
                  route: AppRouter.dashboardAlerts,
                ),
                _buildMenuItem(
                  context,
                  icon: AppIcons.message,
                  title: 'Wiadomości',
                  route: AppRouter.dashboardMessages,
                ),
                _buildMenuItem(
                  context,
                  icon: AppIcons.statistics,
                  title: 'Statystyki',
                  route: AppRouter.dashboardStatistics,
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: AppIcons.settings,
                  title: 'Ustawienia',
                  route: AppRouter.dashboardSettings,
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: ListTile(
              leading: const Icon(AppIcons.logout, color: AppColors.error),
              title: Text(
                'Wyloguj',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                // Handle logout
                context.go(AppRouter.home);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accent : AppColors.grey600,
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.accent.withOpacity(0.1),
      onTap: () {
        context.go(route);
        Navigator.of(context).pop(); // Close drawer
      },
    );
  }
}
