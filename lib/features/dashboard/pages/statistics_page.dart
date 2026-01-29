import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final isTablet = MediaQuery.sizeOf(context).width >= AppSpacing.mobileBreakpoint &&
        MediaQuery.sizeOf(context).width < AppSpacing.tabletBreakpoint;
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return DashboardScaffold(
      title: 'Statystyki',
      currentRoute: AppRouter.dashboardStatistics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie aktywności Twoich ogłoszeń.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: isMobile ? 1.6 : 1.4,
            children: [
              _StatCard(
                title: 'Wyświetlenia',
                value: '1 247',
                subtitle: 'Ostatnie 30 dni',
                icon: AppIcons.visibility,
                isMobile: isMobile,
              ),
              _StatCard(
                title: 'Ulubione',
                value: '89',
                subtitle: 'Zapisane przez użytkowników',
                icon: AppIcons.favorites,
                isMobile: isMobile,
              ),
              _StatCard(
                title: 'Kontakt',
                value: '23',
                subtitle: 'Zapytania / wiadomości',
                icon: AppIcons.message,
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Najpopularniejsze ogłoszenia',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlaceholderList(
            items: const [
              'Biurowiec klasy A, Warszawa Mokotów — 312 wyświetleń',
              'Hala magazynowa, Śląsk — 198 wyświetleń',
              'Lokal handlowy, Kraków — 156 wyświetleń',
            ],
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.isMobile,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  const _PlaceholderList({
    required this.items,
    required this.isMobile,
  });

  final List<String> items;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.trending,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        e,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
