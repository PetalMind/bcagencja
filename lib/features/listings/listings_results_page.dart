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
import '../../core/state/providers/favorites_provider.dart';
import '../../core/services/listing_submission_service.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/login_required_modal.dart';
import '../../widgets/common/nda_required_modal.dart';
import '../../widgets/common/watermarked_image.dart';
import 'widgets/listings_search_bar.dart';

final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Provider strumienia ofert z kolekcji listing_submissions – filtry z query params.
final _publishedListingsProvider = StreamProvider.autoDispose
    .family<List<Property>, ({
      String? searchQuery,
      String? typ,
      double? roiMin,
      double? cenaMin,
      double? cenaMax,
      double? areaMin,
      double? areaMax,
      String? voivodeship,
      String? tenant,
    })>((ref, params) {
  final service = ref.watch(_submissionServiceProvider);
  return service.streamSubmissionsForOffers().map((records) {
    var list = records.map((r) => ListingSubmissionService.propertyFromRecord(r)).toList();
    if (params.searchQuery != null && params.searchQuery!.trim().isNotEmpty) {
      final q = params.searchQuery!.trim().toLowerCase();
      list = list.where((p) {
        return (p.title.toLowerCase().contains(q)) ||
            (p.city.toLowerCase().contains(q)) ||
            (p.location.toLowerCase().contains(q)) ||
            (p.description.toLowerCase().contains(q));
      }).toList();
    }
    if (params.typ != null && params.typ!.isNotEmpty) {
      list = list.where((p) {
        if (params.typ == 'land') return p.propertyType == 'land';
        if (params.typ == 'vacant') {
          const vacant = ['office', 'retail', 'warehouse', 'industrial', 'hotel'];
          return vacant.contains(p.propertyType) && (p.tenant == null || p.tenant!.trim().isEmpty);
        }
        if (params.typ == 'tenanted') {
          const tenanted = ['office', 'retail', 'warehouse', 'industrial', 'hotel'];
          return tenanted.contains(p.propertyType) && p.tenant != null && p.tenant!.trim().isNotEmpty;
        }
        return true;
      }).toList();
    }
    if (params.roiMin != null) {
      list = list.where((p) => (p.roi ?? 0) >= params.roiMin!).toList();
    }
    if (params.cenaMin != null) {
      list = list.where((p) => p.price >= params.cenaMin!).toList();
    }
    if (params.cenaMax != null) {
      list = list.where((p) => p.price <= params.cenaMax!).toList();
    }
    if (params.areaMin != null) {
      list = list.where((p) => p.area >= params.areaMin!).toList();
    }
    if (params.areaMax != null) {
      list = list.where((p) => p.area <= params.areaMax!).toList();
    }
    if (params.voivodeship != null && params.voivodeship!.trim().isNotEmpty) {
      final v = params.voivodeship!.trim().toLowerCase();
      list = list.where((p) {
        final pv = (p.voivodeship ?? '').toLowerCase();
        return pv.contains(v) || pv.replaceAll('woj. ', '').contains(v);
      }).toList();
    }
    if (params.tenant != null && params.tenant!.trim().isNotEmpty) {
      final t = params.tenant!.trim().toLowerCase();
      list = list.where((p) => (p.tenant ?? '').toLowerCase().contains(t)).toList();
    }
    return list;
  });
});

/// Baza ofert (teasery) – główny punkt wejścia dla inwestorów.
/// Model 3-stopniowy: anonim (teasery) → Logowanie + NDA (Level 2) → VDR (Level 3).
class ListingsResultsPage extends ConsumerWidget {
  const ListingsResultsPage({
    super.key,
    this.searchQuery,
    this.typFilter,
    this.roiMin,
    this.cenaMin,
    this.cenaMax,
    this.areaMin,
    this.areaMax,
    this.voivodeship,
    this.tenant,
  });

  final String? searchQuery;
  final String? typFilter;
  final String? roiMin;
  final String? cenaMin;
  final String? cenaMax;
  final String? areaMin;
  final String? areaMax;
  final String? voivodeship;
  final String? tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final params = (
      searchQuery: searchQuery,
      typ: typFilter,
      roiMin: double.tryParse(roiMin ?? ''),
      cenaMin: double.tryParse(cenaMin ?? ''),
      cenaMax: double.tryParse(cenaMax ?? ''),
      areaMin: double.tryParse(areaMin ?? ''),
      areaMax: double.tryParse(areaMax ?? ''),
      voivodeship: voivodeship,
      tenant: tenant,
    );
    final listingsAsync = ref.watch(_publishedListingsProvider(params));
    final showNdaBanner = user != null && user.shouldShowNdaBanner;

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        title: 'Baza ofert',
      ),
      drawer: isMobile ? const MobileMenu() : null,
      body: listingsAsync.when(
        data: (listings) => SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(context, listings.length),
                    if (showNdaBanner) ...[
                      const SizedBox(height: AppSpacing.md),
                      _NdaBanner(isMobile: isMobile),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ListingsSearchBar(
                      searchQuery: searchQuery,
                      cenaMin: cenaMin,
                      cenaMax: cenaMax,
                      areaMin: areaMin,
                      areaMax: areaMax,
                      typFilter: typFilter,
                      roiMin: roiMin,
                      voivodeship: voivodeship,
                      tenant: tenant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (listings.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listings.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _TeaserCard(
                          property: listings[index],
                          appUser: user,
                          isFeatured: index == 0 || listings[index].promoted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
        error: (err, _) {
          debugPrint('=== Błąd ofert (skopiuj link z komunikatu poniżej) ===');
          debugPrint(err.toString());
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Błąd ładowania ofert. Sprawdź połączenie z internetem.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    err.toString(),
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
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  static Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apartment_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Brak zgłoszeń',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Oferty pojawią się tutaj po dodaniu zgłoszeń w formularzu „Chcę sprzedać".',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oferty nieruchomości komercyjnych',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          count > 0 ? '$count ofert dostępnych' : 'Przeglądaj oferty',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Banner „Zaakceptuj NDA aby odblokować pełne oferty" dla INVESTOR_BASIC.
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
              const Icon(Icons.chevron_right, color: AppColors.info),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karta teasera w stylu poziomym (Rightmove/Zoopla).
/// Featured: kolorowy pasek nagłówka. Hover: cień i przesunięcie.
class _TeaserCard extends ConsumerStatefulWidget {
  const _TeaserCard({
    required this.property,
    this.appUser,
    this.isFeatured = false,
  });

  final Property property;
  final AppUser? appUser;
  final bool isFeatured;

  @override
  ConsumerState<_TeaserCard> createState() => _TeaserCardState();
}

class _TeaserCardState extends ConsumerState<_TeaserCard> {
  bool _isHovered = false;

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
    final p = widget.property;
    final imageUrl = p.images.isNotEmpty ? (p.mainImage ?? p.images.first) : null;
    final imageCount = p.images.length;
    final favorites = ref.watch(favoritesProvider);
    final isSaved = favorites.contains(p.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: _isHovered ? AppColors.borderMedium : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: _isHovered ? 0.10 : 0.05),
              blurRadius: _isHovered ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: () => _navigateToPropertyAccess(context, widget.appUser, p.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isFeatured)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
                    color: const Color(0xFF007B6E),
                    child: Text(
                      'WYRÓŻNIONA OFERTA — ${p.propertyTypeLabel.toUpperCase()}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                isMobile
                    ? _buildMobileBody(context, p, imageUrl, imageCount, isSaved)
                    : _buildDesktopBody(context, p, imageUrl, imageCount, isSaved),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context,
    Property p,
    String? imageUrl,
    int imageCount,
    bool isSaved,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: _buildImagePanel(imageUrl, imageCount),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTitleBlock(p)),
                      const SizedBox(width: AppSpacing.sm),
                      _buildSaveButton(p.id, isSaved),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.description,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTagsRow(p),
                  const Spacer(),
                  const Divider(height: AppSpacing.lg, color: AppColors.borderLight),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _buildPriceBlock(p)),
                      _buildContactButton(context, p),
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

  Widget _buildMobileBody(
    BuildContext context,
    Property p,
    String? imageUrl,
    int imageCount,
    bool isSaved,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildImagePanel(imageUrl, imageCount),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTitleBlock(p)),
                  _buildSaveButton(p.id, isSaved),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                p.description,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTagsRow(p),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: AppSpacing.md),
              _buildPriceBlock(p),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: _buildContactButton(context, p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePanel(String? imageUrl, int imageCount) {
    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl != null
            ? WatermarkedImage(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.grey100),
                  errorWidget: (context, url, error) => _imagePlaceholder(),
                ),
              )
            : _imagePlaceholder(),
        if (imageCount > 1)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, size: 12, color: AppColors.white),
                  const SizedBox(width: 4),
                  Text(
                    '1/$imageCount',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: AppSpacing.sm,
          left: AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 11, color: AppColors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 4),
                Text(
                  'Off-Market',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: const Center(
        child: Icon(AppIcons.image, size: 48, color: AppColors.grey300),
      ),
    );
  }

  Widget _buildTitleBlock(Property p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.grey500),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                p.teaserLocationDisplay,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          p.propertyTypeLabel,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildTagsRow(Property p) {
    final tags = <_TagChip>[
      _TagChip(label: p.propertyTypeLabel.toUpperCase(), color: const Color(0xFF007B6E)),
    ];
    if (p.area > 0) {
      tags.add(_TagChip(label: '${p.area.toStringAsFixed(0)} m² GLA', color: AppColors.grey600, outlined: true));
    }
    if (p.tenant != null && p.tenant!.trim().isNotEmpty) {
      tags.add(_TagChip(label: p.tenant!, color: AppColors.grey600, outlined: true));
    }
    if (p.yearBuilt != null && p.yearBuilt! > 0) {
      tags.add(_TagChip(label: 'Rok: ${p.yearBuilt}', color: AppColors.grey600, outlined: true));
    }
    return Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: tags);
  }

  Widget _buildPriceBlock(Property p) {
    final priceDisplay = p.teaserPriceDisplay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceDisplay ?? 'Cena do uzgodnienia',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Zapytaj o szczegóły',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSaveButton(String propertyId, bool isSaved) {
    return IconButton(
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(propertyId),
      icon: Icon(
        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isSaved ? AppColors.accent : AppColors.grey400,
        size: AppSpacing.iconMd,
      ),
      tooltip: isSaved ? 'Usuń z zapisanych' : 'Zapisz',
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, Property p) {
    return OutlinedButton.icon(
      onPressed: () => _navigateToPropertyAccess(context, widget.appUser, p.id),
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: const Text('Szczegóły'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.outlined = false});

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        border: outlined ? Border.all(color: AppColors.borderMedium) : Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: outlined ? AppColors.grey600 : color,
          fontWeight: outlined ? FontWeight.normal : FontWeight.w700,
          letterSpacing: outlined ? 0 : 0.4,
        ),
      ),
    );
  }
}
