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

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final listings = List.generate(5, (i) => Property.mock(i));

    return DashboardScaffold(
      title: 'Moje ogłoszenia',
      currentRoute: AppRouter.dashboardListings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${listings.length} ogłoszeń',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isMobile)
                FilledButton.icon(
                  onPressed: () => context.push(AppRouter.addListing),
                  icon: const Icon(AppIcons.add, size: 20),
                  label: const Text('Dodaj ogłoszenie'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                  ),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRouter.addListing),
                icon: const Icon(AppIcons.add, size: 20),
                label: const Text('Dodaj ogłoszenie'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (listings.isEmpty)
            DashboardEmptyState(
              title: 'Brak ogłoszeń',
              subtitle: 'Dodaj pierwsze ogłoszenie, aby zacząć.',
              actionLabel: 'Dodaj ogłoszenie',
              icon: AppIcons.office,
              onAction: () => context.push(AppRouter.addListing),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (isMobile) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => ListingCard(property: listings[index]),
                  );
                }
                return Column(
                  children: listings
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

