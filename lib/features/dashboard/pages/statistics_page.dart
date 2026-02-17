import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/dashboard_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';

/// Formatuje liczbę z odstępami tysięcy (np. 1247 → "1 247").
String _formatCount(int value) {
  if (value < 1000) return '$value';
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Etykieta ogłoszenia do listy „najpopularniejsze”: typ + lokalizacja — wyświetlenia.
String _listingStatsLabel(Property p) {
  final loc = p.district != null && p.district!.isNotEmpty
      ? '${p.city}, ${p.district}'
      : p.city;
  return '${p.propertyTypeLabel}, $loc — ${_formatCount(p.views)} wyświetleń';
}

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final isTablet = MediaQuery.sizeOf(context).width >= AppSpacing.mobileBreakpoint &&
        MediaQuery.sizeOf(context).width < AppSpacing.tabletBreakpoint;
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    final views = ref.watch(partnerStatsViewsProvider);
    final favorites = ref.watch(partnerStatsFavoritesProvider);
    final contactCount = ref.watch(partnerStatsContactCountProvider);
    final topListings = ref.watch(partnerTopListingsByViewsProvider);

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
                value: _formatCount(views),
                subtitle: 'Łącznie dla Twoich ofert',
                icon: AppIcons.visibility,
                isMobile: isMobile,
              ),
              _StatCard(
                title: 'Ulubione',
                value: _formatCount(favorites),
                subtitle: 'Zapisane przez użytkowników',
                icon: AppIcons.favorites,
                isMobile: isMobile,
              ),
              _StatCard(
                title: 'Kontakt',
                value: _formatCount(contactCount),
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
          topListings.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Brak opublikowanych ofert lub brak wyświetleń.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : _TopListingsList(
                  listings: topListings,
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

class _TopListingsList extends StatelessWidget {
  const _TopListingsList({
    required this.listings,
    required this.isMobile,
  });

  final List<Property> listings;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: listings
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => context.go('/property/${p.id}'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                          _listingStatsLabel(p),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
