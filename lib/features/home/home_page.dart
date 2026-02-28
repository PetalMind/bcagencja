import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/layout/app_footer.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_categories_section.dart';
import 'widgets/home_featured_listings.dart';
import 'widgets/home_tiles_section.dart';
import 'widgets/home_stats_section.dart';
import 'widgets/home_locations_section.dart';
import 'widgets/home_faq_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HomeHeroSection(),
            HomeCategoriesSection(),
            HomeFeaturedListings(),
            HomeTilesSection(),
            HomeStatsSection(),
            HomeLocationsSection(),
            HomeFaqSection(),
            AppFooter(),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }
}
