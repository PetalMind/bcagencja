import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  static const List<_SavedSearch> _mockSearches = [
    _SavedSearch(
      name: 'Biurowce Warszawa',
      summary: 'Biurowiec · Warszawa · 500–2000 m² · do 5 mln zł',
      newCount: 3,
    ),
    _SavedSearch(
      name: 'Hale magazynowe Śląsk',
      summary: 'Magazyn · woj. śląskie · pow. 2000 m²',
      newCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final searches = _mockSearches;

    return DashboardScaffold(
      title: 'Zapisane wyszukiwania',
      currentRoute: AppRouter.dashboardAlerts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Powiadomienia o nowych ofertach pasujących do zapisanych kryteriów.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (searches.isEmpty)
            DashboardEmptyState(
              title: 'Brak zapisanych wyszukiwań',
              subtitle: 'Zapisz wyszukiwanie na stronie wyników, aby otrzymywać powiadomienia o nowych ofertach.',
              actionLabel: 'Przejdź do wyszukiwania',
              icon: AppIcons.notifications,
              actionIcon: AppIcons.search,
              onAction: () => context.push(AppRouter.search),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searches.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final s = searches[index];
                return _SavedSearchTile(
                  name: s.name,
                  summary: s.summary,
                  newCount: s.newCount,
                  isMobile: isMobile,
                  onTap: () => context.push(AppRouter.search),
                  onRemove: () {},
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SavedSearch {
  const _SavedSearch({
    required this.name,
    required this.summary,
    required this.newCount,
  });
  final String name;
  final String summary;
  final int newCount;
}

class _SavedSearchTile extends StatelessWidget {
  const _SavedSearchTile({
    required this.name,
    required this.summary,
    required this.newCount,
    required this.isMobile,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final String summary;
  final int newCount;
  final bool isMobile;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  AppIcons.notifications,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleSmall,
                          ),
                        ),
                        if (newCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              '$newCount',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(AppIcons.chevronRight, size: 20),
                onPressed: onTap,
                color: AppColors.grey400,
              ),
              IconButton(
                icon: const Icon(AppIcons.delete, size: 20),
                onPressed: onRemove,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
