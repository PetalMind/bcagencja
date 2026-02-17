import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_tiles_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(),
      drawer: isMobile ? const MobileMenu() : null,
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HomeHeroSection(),
            HomeTilesSection(),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }
}
