import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/state/models/property_model.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/login_required_modal.dart';
import '../../widgets/common/nda_required_modal.dart';
import '../../widgets/common/watermarked_image.dart';

/// Baza ofert (teasery) – główny punkt wejścia dla inwestorów.
/// Model 3-stopniowy: anonim (teasery) → Logowanie + NDA (Level 2) → VDR (Level 3).
class ListingsResultsPage extends ConsumerWidget {
  const ListingsResultsPage({super.key});

  static List<Property> _mockListings() {
    return List.generate(8, (i) => Property.mock(i));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final listings = _mockListings();
    final showNdaBanner = user != null && user.shouldShowNdaBanner;

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        title: 'Baza ofert',
      ),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(context),
                  if (showNdaBanner) ...[
                    _NdaBanner(isMobile: isMobile),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                  ],
                  SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xxl),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (listings.length >= 4 ? 2 : 2),
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.lg,
                      childAspectRatio: isMobile ? 1.15 : 0.92,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) => _TeaserCard(
                      property: listings[index],
                      appUser: user,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oferty nieruchomości komercyjnych',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Przeglądaj teasery ofert. Aby zobaczyć pełne dane (lokalizacja, galeria), zaloguj się i zaakceptuj NDA. '
          'Dostęp do dokumentów (VDR) wymaga weryfikacji kapitału.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Banner „Zaakceptuj NDA aby odblokować pełne oferty” dla INVESTOR_BASIC.
class _NdaBanner extends StatelessWidget {
  const _NdaBanner({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.info.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => context.go(AppRouter.weryfikacja),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.info, size: 28),
              SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Text(
                  'Zaakceptuj NDA, aby odblokować pełne oferty (lokalizacja, galeria, kontakt)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.info),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karta teasera: 1 zdjęcie, typ, powierzchnia, przedział ceny, region (bez adresu). CTA „Zobacz więcej”.
class _TeaserCard extends StatelessWidget {
  const _TeaserCard({required this.property, this.appUser});

  final Property property;
  final AppUser? appUser;

  /// GUEST: modal „Zaloguj się”. INVESTOR_BASIC: modal „Zaakceptuj NDA”. Pełny dostęp: nawigacja.
  static void _navigateToPropertyAccess(BuildContext context, AppUser? user, String propertyId) {
    final path = '/property/$propertyId';
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;

    if (roleLevel == UserRoleLevel.guest) {
      LoginRequiredModal.show(context, returnTo: path);
      return;
    }
    if (roleLevel == UserRoleLevel.investorBasic) {
      NdaRequiredModal.show(context, returnTo: path);
      return;
    }
    if (!user!.hasIdentityVerifiedAccess) {
      NdaRequiredModal.show(context, returnTo: path);
      return;
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final imageUrl = property.images.isNotEmpty
        ? (property.mainImage ?? property.images.first)
        : null;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => _navigateToPropertyAccess(context, appUser, property.id),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: imageUrl != null
                    ? WatermarkedImage(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey200,
                            child: const Icon(AppIcons.image, size: 48, color: AppColors.grey400),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.grey200,
                        child: const Icon(AppIcons.image, size: 48, color: AppColors.grey400),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.propertyTypeLabel,
                    style: AppTextStyles.overline.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    property.title,
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(AppIcons.area, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${property.area.toStringAsFixed(0)} m²',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        property.formattedPrice,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        property.city,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                  Row(
                    children: [
                      Text(
                        'Zobacz więcej',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(AppIcons.arrowForward, size: AppSpacing.iconSm, color: AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
