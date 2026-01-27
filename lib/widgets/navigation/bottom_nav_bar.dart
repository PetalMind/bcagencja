import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.grey400,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(AppIcons.home),
          label: 'Główna',
        ),
        BottomNavigationBarItem(
          icon: Icon(AppIcons.search),
          label: 'Szukaj',
        ),
        BottomNavigationBarItem(
          icon: Icon(AppIcons.add),
          label: 'Dodaj',
        ),
        BottomNavigationBarItem(
          icon: Icon(AppIcons.favorites),
          label: 'Ulubione',
        ),
        BottomNavigationBarItem(
          icon: Icon(AppIcons.profile),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRouter.home);
            break;
          case 1:
            context.go(AppRouter.search);
            break;
          case 2:
            context.go(AppRouter.addListing);
            break;
          case 3:
            context.go(AppRouter.dashboardFavorites);
            break;
          case 4:
            context.go(AppRouter.dashboard);
            break;
        }
      },
    );
  }
}
