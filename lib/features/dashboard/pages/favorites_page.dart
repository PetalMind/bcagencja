import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../listings/widgets/listing_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final favorites = List.generate(4, (i) => Property.mock(i + 2));

    return DashboardScaffold(
      title: 'Ulubione',
      currentRoute: AppRouter.dashboardFavorites,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${favorites.length} zapisanych ofert',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (favorites.isEmpty)
            DashboardEmptyState(
              title: 'Brak ulubionych',
              subtitle: 'Zapisuj oferty, klikając ikonę serca przy ogłoszeniu.',
              actionLabel: 'Przejdź do wyszukiwania',
              icon: AppIcons.favorites,
              actionIcon: AppIcons.search,
              onAction: () => context.push(AppRouter.search),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (isMobile) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => ListingCard(property: favorites[index]),
                  );
                }
                return Column(
                  children: favorites
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListingCard(property: p),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

