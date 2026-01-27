import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/hero_section.dart';
import 'widgets/promoted_listings.dart';
import 'widgets/latest_listings.dart';
import 'widgets/popular_locations.dart';
import 'widgets/statistics_section.dart';
import 'widgets/testimonials_section.dart';

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
            // Hero section with search
            HeroSection(),
            
            // Promoted listings
            PromotedListings(),
            
            // Latest listings
            LatestListings(),
            
            // Popular locations
            PopularLocations(),
            
            // Statistics
            StatisticsSection(),
            
            // Testimonials
            TestimonialsSection(),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }
}
