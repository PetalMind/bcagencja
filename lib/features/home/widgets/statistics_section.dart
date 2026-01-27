import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    final stats = [
      {'value': '15,000+', 'label': 'Aktywnych ofert'},
      {'value': '50,000+', 'label': 'Zadowolonych klientów'},
      {'value': '200+', 'label': 'Zweryfikowanych agentów'},
      {'value': '100+', 'label': 'Miast w Polsce'},
    ];
    
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.containerMaxWidth,
          ),
          child: Column(
            children: [
              Text(
                'Zaufało nam już tysiące klientów',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              if (!isMobile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats.map((stat) {
                    return _buildStatCard(
                      value: stat['value'] as String,
                      label: stat['label'] as String,
                    );
                  }).toList(),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final stat = stats[index];
                    return _buildStatCard(
                      value: stat['value'] as String,
                      label: stat['label'] as String,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
