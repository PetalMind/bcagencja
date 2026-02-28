import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';
import '../../../core/services/vdr_document_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/save_to_collection_modal.dart';
import 'contact_form.dart';

/// Karta informacyjna oferty: cena, parametry, kontakt, akcje.
/// Mobile-first: zwięzłe sekcje, grid parametrów, CTA do formularza w bottom sheet.
/// Desktop: pełny formularz, sticky-friendly layout.
class PropertyInfoPanel extends ConsumerWidget {
  final Property property;

  /// Na mobile: wywołane po naciśnięciu "Zapytaj o ofertę" – np. otwarcie bottom sheet z formularzem.
  final VoidCallback? onRequestContact;

  /// Poziom 3: użytkownik ma dostęp do VDR.
  final bool hasVdrAccess;

  const PropertyInfoPanel({
    super.key,
    required this.property,
    this.onRequestContact,
    this.hasVdrAccess = false,
  });

  void _downloadTeaserPdf(BuildContext context) {
    // TODO: integracja z endpointem teaser PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teaser PDF będzie dostępny wkrótce'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareProperty(BuildContext context) async {
    String shareUrl = '';
    try {
      shareUrl = '${Uri.base.origin}/property/${property.id}';
    } catch (_) {}
    final text = shareUrl.isEmpty
        ? '${property.title}\n${property.location}'
        : '${property.title}\n${property.location}\n$shareUrl';
    await Share.share(
      text,
      subject: property.title,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Udostępniono ofertę'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isNarrow = screenWidth < AppSpacing.tabletBreakpoint;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: isMobile ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // —— Zapisz + Udostępnij ——
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SaveOfferButton(property: property),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CustomButton(
                    label: 'Udostępnij',
                    icon: AppIcons.share,
                    onPressed: () => _shareProperty(context),
                    variant: ButtonVariant.outlined,
                    size: ButtonSize.small,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // —— Cena ——
          _SectionHeader(
            label: 'Cena',
            icon: AppIcons.price,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              isMobile ? AppSpacing.sm : AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.formattedPrice,
                  style: AppTextStyles.priceLarge.copyWith(
                    fontSize: isMobile ? 26 : 32,
                  ),
                ),
                if (property.pricePerSqm != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          _SectionDivider(),

          // —— Parametry ——
          _SectionHeader(
            label: 'Parametry',
            icon: AppIcons.area,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: isMobile ? AppSpacing.sm : AppSpacing.md,
            ),
            child: isMobile || isNarrow
                ? _buildParametersGrid()
                : _buildParametersList(),
          ),

          _SectionDivider(),

          // —— Kontakt ——
          _SectionHeader(
            label: 'Kontakt',
            icon: AppIcons.phone,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              isMobile ? AppSpacing.sm : AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile)
                  _ContactSection(
                    onRequestContact: null,
                    onFormSuccess: () {},
                  )
                else if (onRequestContact != null)
                  CustomButton(
                    label: 'Zapytaj o ofertę',
                    icon: AppIcons.message,
                    onPressed: onRequestContact,
                    fullWidth: true,
                    size: ButtonSize.large,
                  ),
                const SizedBox(height: AppSpacing.sm),
                CustomButton(
                  label: 'Pobierz teaser PDF',
                  icon: AppIcons.download,
                  onPressed: () => _downloadTeaserPdf(context),
                  fullWidth: true,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                ),
              ],
            ),
          ),

          // —— VDR (Poziom 3) ——
          if (hasVdrAccess) _VdrSidebarSection(property: property),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildParametersGrid() {
    final items = <_ParamItem>[
      _ParamItem(AppIcons.area, 'Powierzchnia', '${property.area.toStringAsFixed(0)} m²'),
    ];
    if (property.floors > 0) {
      items.add(_ParamItem(AppIcons.floors, 'Kondygnacje', '${property.floors}'));
    }
    if (property.parkingSpaces != null && property.parkingSpaces! > 0) {
      items.add(_ParamItem(AppIcons.parkingSpaces, 'Parking', '${property.parkingSpaces} miejsc'));
    }
    if (property.ceilingHeight != null) {
      items.add(_ParamItem(AppIcons.ceilingHeight, 'Wys. użytkowa', '${property.ceilingHeight!.toStringAsFixed(1)} m'));
    }
    if (property.buildingClass != null) {
      items.add(_ParamItem(Icons.grade_rounded, 'Klasa', property.buildingClass!));
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map((e) => _ParameterChip(
                icon: e.icon,
                label: e.label,
                value: e.value,
              ))
          .toList(),
    );
  }

  Widget _buildParametersList() {
    return Column(
      children: [
        _buildParameterRow(AppIcons.area, 'Powierzchnia', '${property.area.toStringAsFixed(0)} m²'),
        if (property.floors > 0)
          _buildParameterRow(AppIcons.floors, 'Kondygnacje', '${property.floors}'),
        if (property.parkingSpaces != null && property.parkingSpaces! > 0)
          _buildParameterRow(AppIcons.parkingSpaces, 'Parking', '${property.parkingSpaces} miejsc'),
        if (property.ceilingHeight != null)
          _buildParameterRow(AppIcons.ceilingHeight, 'Wys. użytkowa', '${property.ceilingHeight!.toStringAsFixed(1)} m'),
        if (property.buildingClass != null)
          _buildParameterRow(Icons.grade_rounded, 'Klasa', property.buildingClass!),
      ],
    );
  }

  Widget _buildParameterRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParamItem {
  final IconData icon;
  final String label;
  final String value;
  _ParamItem(this.icon, this.label, this.value);
}

/// Przycisk „Zapisz ofertę” / „Zapisano” – otwiera modal kolekcji lub usuwa z zapisanych.
/// Nie wyświetlany dla ofert własnego autorstwa (własna oferta nie może być zapisana do ulubionych).
/// Sekcja kontaktu: przycisk "Zapytaj o ofertę" -> po kliknięciu formularz z animacją.
class _ContactSection extends StatefulWidget {
  const _ContactSection({
    this.onRequestContact,
    required this.onFormSuccess,
  });
  final VoidCallback? onRequestContact;
  final VoidCallback onFormSuccess;

  @override
  State<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<_ContactSection> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_showForm)
          CustomButton(
            label: 'Zapytaj o ofertę',
            icon: AppIcons.message,
            onPressed: () => setState(() => _showForm = true),
            fullWidth: true,
            size: ButtonSize.large,
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ContactForm(
                  compact: true,
                  onSuccess: () {
                    setState(() => _showForm = false);
                    widget.onFormSuccess();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VdrSidebarSection extends ConsumerWidget {
  const _VdrSidebarSection({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = property.vdrDocuments;
    final service = ref.read(vdrDocumentServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionDivider(),
        _SectionHeader(label: 'Virtual Data Room', icon: Icons.folder_special_rounded),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Pobrane pliki zawierają znak wodny (Twoje dane, data, IP).',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (docs.isEmpty)
                  CustomButton(
                    label: 'Otwórz VDR',
                    icon: Icons.folder_open_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Brak dokumentów w VDR'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    fullWidth: true,
                    size: ButtonSize.large,
                  )
                else
                  CustomButton(
                    label: 'Pobierz pliki',
                    icon: AppIcons.download,
                    onPressed: () => _downloadFirstDoc(context, service),
                    fullWidth: true,
                    size: ButtonSize.large,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadFirstDoc(BuildContext context, VdrDocumentService service) async {
    if (property.vdrDocuments.isEmpty) return;
    final doc = property.vdrDocuments.first;
    final filename = doc.name.endsWith('.pdf') ? doc.name : '${doc.name}.pdf';
    final result = await service.downloadWithWatermark(
      listingId: property.id,
      documentPath: doc.storagePath,
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
}

class _SaveOfferButton extends ConsumerWidget {
  const _SaveOfferButton({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user != null && property.ownerId == user.id) {
      return const SizedBox.shrink();
    }

    final favoriteIds = ref.watch(favoritesProvider);
    final smart = ref.watch(smartFavoritesProvider);
    final isSaved = favoriteIds.contains(property.id);
    final entry = smart.entryFor(property.id);

    if (isSaved) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              label: 'Zapisano',
              icon: AppIcons.favorites,
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
              fullWidth: true,
              onPressed: () {
                showSaveToCollectionModal(
                  context: context,
                  property: property,
                  existingEntry: entry,
                );
              },
            ),
          ),
        ],
      );
    }
    return CustomButton(
      label: 'Zapisz ofertę',
      icon: AppIcons.favoriteBorder,
      variant: ButtonVariant.outlined,
      size: ButtonSize.small,
      fullWidth: true,
      onPressed: () {
        showSaveToCollectionModal(
          context: context,
          property: property,
          existingEntry: null,
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(height: 1, color: AppColors.borderLight),
    );
  }
}

class _ParameterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ParameterChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
