import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/sidebar.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;
    
    return Scaffold(
      appBar: const AppBarCustom(),
      drawer: !isDesktop ? const Sidebar() : null,
      body: Row(
        children: [
          if (isDesktop)
            const SizedBox(
              width: 280,
              child: Sidebar(),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Witaj w panelu użytkownika', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: AppSpacing.lg),
                  
                  GridView.count(
                    crossAxisCount: screenWidth < AppSpacing.mobileBreakpoint ? 1 : 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Moje ogłoszenia', '5', Icons.apartment_rounded),
                      _buildStatCard('Ulubione', '12', Icons.favorite_rounded),
                      _buildStatCard('Wiadomości', '3', Icons.message_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.orange),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
