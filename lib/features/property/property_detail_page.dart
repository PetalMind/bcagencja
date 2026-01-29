import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/property/mobile_contact_bar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/state/models/property_model.dart';
import '../../core/router/app_router.dart';
import 'widgets/property_gallery.dart';
import 'widgets/property_info_panel.dart';
import 'widgets/contact_form.dart';
import 'widgets/property_description.dart';
import 'widgets/property_parameters.dart';
import 'widgets/property_amenities.dart';
import 'widgets/similar_listings.dart';

class PropertyDetailPage extends StatelessWidget {
  final String propertyId;
  
  const PropertyDetailPage({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint &&
        screenWidth < AppSpacing.tabletBreakpoint;
    
    // Get property data - in real app this would come from API/state management
    final property = _getPropertyById(propertyId);
    
    final isDesktop = !isMobile && !isTablet;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      body: isDesktop
          ? _buildDesktopBody(context, property)
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildContentContainer(
                    context,
                    property: property,
                    isMobile: isMobile,
                    includePanelInFlow: true,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: isMobile
          ? MobileContactBar(
              price: property.formattedPrice,
              phone: property.ownerPhone,
              onMessageTap: () => _openContactSheet(context),
            )
          : null,
    );
  }

  Widget _buildDesktopBody(BuildContext context, Property property) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _buildContentContainer(
              context,
              property: property,
              isMobile: false,
              includePanelInFlow: false,
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
              child: PropertyInfoPanel(property: property),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentContainer(
    BuildContext context,
    {required Property property,
    required bool isMobile,
    required bool includePanelInFlow}) {
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
                                  color: AppColors.success.withOpacity(0.1),
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
                    _buildMobileLayout(context, property)
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
                  
                  // Similar listings
                  SimilarListings(propertyId: property.id),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
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
  
  Widget _buildMobileLayout(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          PropertyGallery(images: property.images),
          const SizedBox(height: AppSpacing.xl),
          PropertyInfoPanel(
            property: property,
            onRequestContact: () => _openContactSheet(context),
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
        
        // Map placeholder
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.map,
                      size: 48,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Mapa Google Maps',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${property.city}, ${property.district}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
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
  
  Property _getPropertyById(String id) {
    // Extract number from id (e.g., "property_2" -> 2)
    final index = int.tryParse(id.replaceAll('property_', '')) ?? 0;
    return Property.mock(index);
  }
}
