import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/dashboard_providers.dart';
import '../../core/services/vdr_document_service.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/property/mobile_contact_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/property_model.dart';
import '../../core/state/providers/favorites_provider.dart';
import '../../core/router/app_router.dart';
import 'widgets/property_gallery.dart';
import 'widgets/activity_timeline.dart';
import 'widgets/property_info_panel.dart';
import 'widgets/contact_form.dart';
import 'widgets/property_description.dart';
import 'widgets/property_parameters.dart';
import 'widgets/property_amenities.dart';
import 'widgets/property_map.dart';
import 'widgets/similar_listings.dart';

/// Szczegóły oferty z 3-stopniowym modelem dostępu: teaser → Level 2 (pełna oferta) → VDR.
class PropertyDetailPage extends ConsumerWidget {
  final String propertyId;
  
  const PropertyDetailPage({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final propertyAsync = ref.watch(propertyDetailProvider(propertyId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint &&
        screenWidth < AppSpacing.tabletBreakpoint;
    final isDesktop = !isMobile && !isTablet;
    final property = propertyAsync.asData?.value;
    final canEdit = property != null &&
        user != null &&
        RolePermissions.canEditListing(
          user.effectiveRoleLevel,
          user.id,
          property.ownerId,
        );
    final appBarActionsPrepend = canEdit
        ? [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/property/$propertyId/edit'),
              tooltip: 'Edytuj',
            ),
          ]
        : null;

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        actionsPrepend: appBarActionsPrepend,
      ),
      body: propertyAsync.when(
        data: (property) {
          if (property == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: AppColors.grey400),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Oferta nie została znaleziona',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          final showTeaserOnly = user == null || !user.hasIdentityVerifiedAccess;
          final hasVdrAccess = user != null && user.hasVdrAccess(propertyId);

          if (showTeaserOnly) {
            return Stack(
              children: [
                if (user != null)
                  _RecordRecentlyViewed(
                    userId: user.id,
                    propertyId: property.id,
                    title: property.title,
                    city: property.city,
                  ),
                _PropertyTeaserView(
                  property: property,
                  propertyId: propertyId,
                ),
              ],
            );
          }

          return Stack(
            children: [
              _RecordRecentlyViewed(
                userId: user.id,
                propertyId: property.id,
                title: property.title,
                city: property.city,
              ),
              isDesktop
                  ? _buildDesktopBody(context, ref, property, hasVdrAccess)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildContentContainer(
                            context,
                            ref: ref,
                            property: property,
                            propertyId: propertyId,
                            isMobile: isMobile,
                            includePanelInFlow: true,
                            hasVdrAccess: hasVdrAccess,
                          ),
                        ],
                      ),
                    ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Błąd ładowania oferty',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: propertyAsync.maybeWhen(
        data: (p) {
          if (p == null) return null;
          final showTeaser = user == null || !user.hasIdentityVerifiedAccess;
          return !showTeaser && isMobile
              ? MobileContactBar(
                  price: p.formattedPrice,
                  phone: p.ownerPhone,
                  onMessageTap: () => _openContactSheet(context),
                )
              : null;
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, WidgetRef ref, Property property, bool hasVdrAccess) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _buildContentContainer(
              context,
              ref: ref,
              property: property,
              propertyId: propertyId,
              isMobile: false,
              includePanelInFlow: false,
              hasVdrAccess: hasVdrAccess,
            ),
          ),
        ),
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.md,
                right: AppSpacing.xl,
                bottom: AppSpacing.xxl,
              ),
              child: PropertyInfoPanel(
                property: property,
                hasVdrAccess: hasVdrAccess,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentContainer(
    BuildContext context, {
    required WidgetRef ref,
    required Property property,
    required String propertyId,
    required bool isMobile,
    required bool includePanelInFlow,
    required bool hasVdrAccess,
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.containerMaxWidth,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          if (!isMobile) _buildBreadcrumbs(context, property),
          const SizedBox(height: AppSpacing.lg),
          // Title and location
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : 0,
            ),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.title,
                                style: isMobile
                                    ? AppTextStyles.headlineSmall
                                    : AppTextStyles.headlineLarge,
                              ),
                            ),
                            if (property.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      AppIcons.verified,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Zweryfikowane',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              AppIcons.location,
                              size: 20,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                property.location,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              AppIcons.visibility,
                              size: 16,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${property.views} wyświetleń',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              AppIcons.favorites,
                              size: 16,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${property.favorites} polubień',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Dodano: ${_formatDate(property.createdAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  // Gallery (and panel on mobile/tablet when in flow)
                  if (includePanelInFlow)
                    _buildMobileLayout(context, property, hasVdrAccess)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: PropertyGallery(images: property.images),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyDescription(
                      title: 'Opis',
                      description: property.description,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Parameters
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyParameters(property: property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Amenities
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: PropertyAmenities(property: property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Location
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.md : 0,
                    ),
                    child: _buildLocationSection(property),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // VDR: CTA lub sekcja dokumentów
                  if (hasVdrAccess)
                    _buildVdrSection(context, ref, propertyId, property, isMobile)
                  else
                    _buildVdrCta(context, propertyId, isMobile),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Historia aktywności (gdy oferta zapisana)
                  if (ref.watch(favoritesProvider).contains(property.id)) ...[
                    ActivityTimeline(property: property, isMobile: isMobile),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                  
                  // Similar listings
                  SimilarListings(property: property),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
  }

  Widget _buildVdrCta(BuildContext context, String listingId, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special_outlined, color: AppColors.primaryDark, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Dostęp do dokumentów (VDR)',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aby przeglądać operaty, umowy najmu i audyty, złóż wniosek o weryfikację kapitału (Proof of Funds). '
              'Dyrektor obszaru zweryfikuje dokumenty i przyzna dostęp do Virtual Data Room.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => _openVdrRequestSheet(context, listingId),
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text('Złóż wniosek o dostęp VDR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVdrRequestSheet(BuildContext context, String listingId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Wniosek o dostęp do VDR',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Funkcja uploadu Proof of Funds (promesa / wyciąg) i weryfikacja przez Dyrektora będzie dostępna w kolejnej iteracji.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVdrSection(
    BuildContext context,
    WidgetRef ref,
    String listingId,
    Property property,
    bool isMobile,
  ) {
    final service = ref.read(vdrDocumentServiceProvider);
    final docs = property.vdrDocuments;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, color: AppColors.success, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Virtual Data Room',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              docs.isEmpty
                  ? 'Masz dostęp do dokumentów tej oferty. Lista dokumentów pojawi się po dodaniu ich do oferty w panelu agenta. Każde pobranie jest oznaczane Twoim imieniem, datą i adresem IP (znak wodny).'
                  : 'Pobierz dokumenty z dynamicznym znakiem wodnym (Twoje dane, data, IP – do śledzenia ewentualnych wycieków).',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (docs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ...docs.map((doc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryDark, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          doc.name,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _downloadVdrDocument(
                          context,
                          service,
                          listingId: listingId,
                          documentPath: doc.storagePath,
                          filename: doc.name.endsWith('.pdf') ? doc.name : '${doc.name}.pdf',
                        ),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Pobierz PDF'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadVdrDocument(
    BuildContext context,
    VdrDocumentService service, {
    required String listingId,
    required String documentPath,
    required String filename,
  }) async {
    if (!context.mounted) return;
    final result = await service.downloadWithWatermark(
      listingId: listingId,
      documentPath: documentPath,
      filename: filename,
    );
    if (!context.mounted) return;
    final snackBar = switch (result) {
      VdrDownloadSuccess() => SnackBar(
          content: Text('Pobrano: $filename (z Twoim znakiem wodnym)'),
          backgroundColor: AppColors.success,
        ),
      VdrDownloadFailure(:final message) => SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
    };
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildBreadcrumbs(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(AppRouter.home),
            child: Text(
              'Strona główna',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          GestureDetector(
            onTap: () => context.go(AppRouter.searchResults),
            child: Text(
              'Wyszukiwanie',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          Text(
            property.city,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
          ),
          Expanded(
            child: Text(
              property.propertyTypeLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(BuildContext context, Property property, bool hasVdrAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          PropertyGallery(images: property.images),
          const SizedBox(height: AppSpacing.xl),
          PropertyInfoPanel(
            property: property,
            onRequestContact: () => _openContactSheet(context),
            hasVdrAccess: hasVdrAccess,
          ),
        ],
      ),
    );
  }

  void _openContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zapytaj o ofertę',
                    style: AppTextStyles.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ContactForm(
                compact: true,
                onSuccess: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLocationSection(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokalizacja',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        
        PropertyMap(property: property, height: 300),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Location details
        Text(
          'Lokalizacja biznesowa',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _getLocationDescription(property),
          style: AppTextStyles.bodyMedium,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Nearby points / Access
        Text(
          'Dostęp i infrastruktura',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildNearbyPoint('Węzeł autostradowy', '3 km', AppIcons.directions),
        _buildNearbyPoint('Port lotniczy', '15 km', Icons.flight_rounded),
        _buildNearbyPoint('Stacja kolejowa', '5 km', Icons.train_rounded),
        _buildNearbyPoint('Centrum biznesowe', '2 km', Icons.business_rounded),
      ],
    );
  }
  
  Widget _buildNearbyPoint(String name, String distance, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(name, style: AppTextStyles.bodyMedium),
          ),
          Text(
            distance,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Dzisiaj';
    } else if (difference.inDays == 1) {
      return 'Wczoraj';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dni temu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tyg. temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
  
  String _getLocationDescription(Property property) {
    switch (property.propertyType) {
      case 'office':
        return 'Nieruchomość położona w prestiżowej dzielnicy biznesowej ${property.district}, ${property.city}. Doskonała lokalizacja w centrum aktywności gospodarczej z rozwiniętą infrastrukturą. Bezpośredni dostęp do węzłów komunikacyjnych - metro, liczne linie autobusowe. W okolicy znajdują się biura międzynarodowych korporacji, hotele biznesowe, restauracje i centra konferencyjne. Idealna lokalizacja dla firm poszukujących prestiżowej siedziby.';
      case 'warehouse':
        return 'Obiekt strategicznie usytuowany przy głównych arteriach komunikacyjnych w ${property.district}, ${property.city}. Doskonały dojazd drogami krajowymi i autostradą. W pobliżu węzły logistyczne i centra dystrybucyjne. Lokalizacja zapewnia efektywny transport i dostęp do kluczowych rynków zbytu. Pełna infrastruktura techniczna, tereny przemysłowe w sąsiedztwie.';
      case 'retail':
        return 'Nieruchomość w centrum handlowym ${property.city}, ${property.district}. Lokalizacja o wysokim natężeniu ruchu pieszego i samochodowego. Otoczenie biurowców, obiektów usługowych i mieszkalnych zapewnia stały ruch klientów. Doskonała widoczność i dostępność komunikacyjna. Idealne dla retailu premium, gastronomii i usług.';
      case 'industrial':
        return 'Kompleks przemysłowy położony w strefie przemysłowej ${property.district}, ${property.city}. Doskonały dojazd dla transportu ciężkiego, bliskość autostrady i linii kolejowych. Pełna infrastruktura techniczna - energia, gaz, woda. Otoczenie obiektów produkcyjnych i logistycznych. Idealna lokalizacja dla działalności przemysłowej i magazynowej.';
      case 'hotel':
        return 'Obiekt hotelarski w atrakcyjnej lokalizacji w ${property.district}, ${property.city}. Bliskość centrum miasta, zabytków i atrakcji turystycznych. Doskonała dostępność komunikacyjna - lotnisko, dworzec, metro. Otoczenie biznesowe z centrami konferencyjnymi i biurami. Wysoki potencjał inwestycyjny w segmencie hotelarskim.';
      case 'land':
        return 'Działka inwestycyjna w dynamicznie rozwijającej się dzielnicy ${property.district}, ${property.city}. Przeznaczenie w MPZP pozwalające na zabudowę komercyjną. Wszystkie media w granicy działki. Doskonała lokalizacja z perspektywą rozwoju - w pobliżu nowe osiedla mieszkaniowe i obiekty komercyjne. Wysoki potencjał wzrostu wartości.';
      default:
        return 'Nieruchomość komercyjna w lokalizacji ${property.district}, ${property.city}. Dobry dostęp komunikacyjny i rozwinięta infrastruktura. Perspektywiczna lokalizacja inwestycyjna.';
    }
  }
  
}

/// Rejestruje obejrzenie oferty w „Ostatnio oglądane” (Firestore) – raz przy wejściu na stronę.
class _RecordRecentlyViewed extends StatefulWidget {
  const _RecordRecentlyViewed({
    required this.userId,
    required this.propertyId,
    required this.title,
    required this.city,
  });

  final String userId;
  final String propertyId;
  final String title;
  final String city;

  @override
  State<_RecordRecentlyViewed> createState() => _RecordRecentlyViewedState();
}

class _RecordRecentlyViewedState extends State<_RecordRecentlyViewed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context);
      container.read(recentlyViewedServiceProvider).recordView(
            widget.userId,
            widget.propertyId,
            widget.title,
            widget.city,
          );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Widok teasera oferty: 1 zdjęcie, typ, powierzchnia, cena, region (bez adresu), krótki opis. CTA → logowanie/NDA.
class _PropertyTeaserView extends ConsumerWidget {
  const _PropertyTeaserView({required this.property, required this.propertyId});

  final Property property;
  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final path = '/property/$propertyId';

    return SingleChildScrollView(
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
                Row(
                  children: [
                    Text(
                      property.propertyTypeLabel,
                      style: AppTextStyles.overline.copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 12, color: AppColors.primaryDark),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Off-Market Exclusive',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  property.title,
                  style: (isMobile ? AppTextStyles.headlineSmall : AppTextStyles.headlineLarge)
                      .copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(AppIcons.location, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      property.teaserLocationDisplay,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                PropertyGallery(
                  images: property.images.isEmpty
                      ? []
                      : property.images.sublist(0, 1),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.area, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'GLA: ${property.area.toStringAsFixed(0)} m²',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (property.teaserPriceDisplay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          property.teaserPriceDisplay!,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (property.tenant != null && property.tenant!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Najemca: ${property.tenant}',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (property.roi != null && property.roi! > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Yield: ${property.roi!.toStringAsFixed(1)}%',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PropertyDescription(
                  title: 'Opis',
                  description: property.description.length > 280
                      ? '${property.description.substring(0, 280)}...'
                      : property.description,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark.withValues(alpha: 0.05),
                        AppColors.primaryDark.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pełna oferta i dokumenty',
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aby zobaczyć dokładną lokalizację, pełną galerię i dane kontaktowe, zaloguj się i zaakceptuj regulamin oraz NDA (weryfikacja LinkedIn lub NIP). '
                        'Dostęp do dokumentów (VDR) wymaga dodatkowej weryfikacji kapitału.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () {
                          if (user == null) {
                            context.go('${AppRouter.logowanie}?returnTo=${Uri.encodeComponent(path)}');
                          } else {
                            context.go('${AppRouter.weryfikacja}?returnTo=${Uri.encodeComponent(path)}');
                          }
                        },
                        icon: const Icon(Icons.verified_user_outlined, size: 20),
                        label: Text(
                          user == null
                              ? 'Zaloguj się i zaakceptuj NDA'
                              : 'Dokończ weryfikację (NDA)',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
