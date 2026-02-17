import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../listings/widgets/listing_card.dart';

/// Strona „Zapisane oferty” – lista ofert dodanych do ulubionych (zapisanych).
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final favoriteIds = ref.watch(favoritesProvider);
    final favorites = favoriteIds
        .map((id) => Property.fromMockId(id))
        .whereType<Property>()
        .toList();

    return DashboardScaffold(
      title: 'Zapisane oferty',
      currentRoute: AppRouter.dashboardFavorites,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            favoriteIds.isEmpty
                ? 'Brak zapisanych ofert'
                : '${favorites.length} zapisanych ofert',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (favorites.isEmpty)
            DashboardEmptyState(
              title: 'Brak zapisanych ofert',
              subtitle: 'Zapisuj oferty, klikając ikonę serca przy ogłoszeniu lub przycisk „Zapisz ofertę” na stronie szczegółów.',
              actionLabel: 'Przejdź do bazy ofert',
              icon: AppIcons.favorites,
              actionIcon: AppIcons.search,
              onAction: () => context.push(AppRouter.oferty),
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

