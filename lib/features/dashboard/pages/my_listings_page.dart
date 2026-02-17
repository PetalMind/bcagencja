import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/services/listings_service.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../listings/widgets/listing_card.dart';

final _listingsServiceProvider = Provider<ListingsService>((ref) => ListingsService());

/// Stream ofert bieżącego użytkownika (agent) – kolekcja listings, ownerId == uid.
final _myListingsProvider = StreamProvider.autoDispose<List<Property>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(_listingsServiceProvider).streamMyListings(ownerId: user.id);
});

/// Widok „Moje ogłoszenia” – oferty agenta z Firestore (ownerId == currentUser).
class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final listingsAsync = ref.watch(_myListingsProvider);

    return DashboardScaffold(
      title: 'Moje ogłoszenia',
      currentRoute: AppRouter.dashboardListings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          listingsAsync.when(
            data: (listings) => Text(
              '${listings.length} ogłoszeń',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            loading: () => Text(
              'Ładowanie…',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            error: (_, _) => Text(
              '—',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          listingsAsync.when(
            data: (listings) {
              if (listings.isEmpty) {
                return DashboardEmptyState(
                  title: 'Brak ogłoszeń',
                  subtitle: 'Dodaj pierwsze ogłoszenie, aby zacząć.',
                  actionLabel: 'Dodaj ogłoszenie',
                  icon: AppIcons.office,
                  onAction: () => context.push(AppRouter.chceSprzedac),
                );
              }
              return LayoutBuilder(
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
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (err, stackTrace) {
              final errStr = err.toString();
              final stackStr = stackTrace?.toString() ?? '';
              debugPrint('=== BŁĄD ŁADOWANIA OGŁOSZEŃ (skopiuj z konsoli) ===');
              debugPrint(errStr);
              if (stackStr.isNotEmpty) debugPrint(stackStr);
              debugPrint('=== KONIEC ===');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Błąd ładowania ogłoszeń.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        errStr,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
