import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Dane jednej opcji: wartość, etykieta, mikrokopia, ikona, URL zdjęcia, opcjonalny badge.
class _PropertyTypeOption {
  const _PropertyTypeOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    this.badge,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  final String? badge; // np. "Najpopularniejsze", "Najszybsza sprzedaż"
}

/// Krok 1: Typ nieruchomości – grid (desktop) ze zdjęciami, badge'ami, hoverem; carousel (mobile).
class Step1PropertyType extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final VoidCallback? onTypeSelected;
  final bool readOnly;

  const Step1PropertyType({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.onTypeSelected,
    this.readOnly = false,
  });

  @override
  State<Step1PropertyType> createState() => _Step1PropertyTypeState();
}

class _Step1PropertyTypeState extends State<Step1PropertyType> {
  late PageController _pageController;
  int _currentPage = 0;

  static const List<_PropertyTypeOption> _options = [
    _PropertyTypeOption(
      value: 'retail',
      label: 'Lokal handlowy',
      subtitle: 'Z najemcą lub pustostan',
      icon: Icons.store_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&q=80',
      badge: 'Najpopularniejsze',
    ),
    _PropertyTypeOption(
      value: 'office',
      label: 'Budynek biurowy',
      subtitle: 'Klasy A, B lub C',
      icon: Icons.business_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400&q=80',
    ),
    _PropertyTypeOption(
      value: 'land',
      label: 'Grunt inwestycyjny',
      subtitle: 'Działki pod zabudowę',
      icon: Icons.landscape_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1500387467466-e730000779eb?w=400&q=80',
      badge: 'Najszybsza sprzedaż',
    ),
    _PropertyTypeOption(
      value: 'warehouse',
      label: 'Hala magazynowa',
      subtitle: 'Logistyka i produkcja',
      icon: Icons.warehouse_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1566895733044-0c2c3650a8e8?w=400&q=80',
    ),
    _PropertyTypeOption(
      value: 'under_construction',
      label: 'Obiekt w budowie',
      subtitle: 'Deweloperka, rozbudowa',
      icon: Icons.construction_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80',
    ),
    _PropertyTypeOption(
      value: 'unsure',
      label: 'Pomóż mi wybrać',
      subtitle: 'Krótki kwestionariusz pomoże dobrać typ',
      icon: Icons.help_outline_rounded,
      imageUrl: 'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Co chcesz sprzedać?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Wybierz typ nieruchomości:',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          IgnorePointer(
            ignoring: widget.readOnly,
            child: isMobile ? _buildMobileCarousel(context) : _buildDesktopGrid(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.ctaHighlight),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Nie martw się – pomożemy dobrać najlepszą kategorię',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(BuildContext context) {
    const double cardMaxWidth = 280;
    const double imageHeight = 140;

    const double textBlockHeight = 80;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: cardMaxWidth / (imageHeight + textBlockHeight),
          children: _options.map((o) => _buildDesktopCard(o, imageHeight)).toList(),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(_PropertyTypeOption o, double imageHeight) {
    final selected = widget.formData.propertyType == o.value;
    return _DesktopPropertyCard(
      selected: selected,
      onTap: () {
        widget.formData.propertyType = o.value;
        widget.onDataChanged(widget.formData);
        widget.onTypeSelected?.call();
      },
      imageHeight: imageHeight,
      option: o,
    );
  }

  Widget _buildMobileCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _buildMobileCard(_options[index]),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CarouselDot(active: _currentPage == 0),
            const SizedBox(width: AppSpacing.xs),
            _CarouselDot(active: _currentPage == 1),
            const SizedBox(width: AppSpacing.xs),
            _CarouselDot(active: _currentPage == 2),
            const SizedBox(width: AppSpacing.xs),
            _CarouselDot(active: _currentPage == 3),
            const SizedBox(width: AppSpacing.xs),
            _CarouselDot(active: _currentPage == 4),
            const SizedBox(width: AppSpacing.xs),
            _CarouselDot(active: _currentPage == 5),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_currentPage + 1}/${_options.length}',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Wstecz'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.grey600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  final o = _options[_currentPage];
                  widget.formData.propertyType = o.value;
                  widget.onDataChanged(widget.formData);
                  widget.onTypeSelected?.call();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Wybierz: ${_options[_currentPage].label}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileCard(_PropertyTypeOption o) {
    final selected = widget.formData.propertyType == o.value;
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.08) : AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          widget.formData.propertyType = o.value;
          widget.onDataChanged(widget.formData);
          widget.onTypeSelected?.call();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                    child: CachedNetworkImage(
                      imageUrl: o.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.grey200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.grey200,
                        child: Icon(o.icon, size: 48, color: AppColors.grey400),
                      ),
                    ),
                  ),
                  if (o.badge != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.ctaHighlight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Text(
                          o.badge!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      o.label,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: selected ? AppColors.accent : AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      o.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta typu nieruchomości na desktopie: zdjęcie, badge, tekst, subtelny hover.
class _DesktopPropertyCard extends StatefulWidget {
  const _DesktopPropertyCard({
    required this.selected,
    required this.onTap,
    required this.imageHeight,
    required this.option,
  });

  final bool selected;
  final VoidCallback onTap;
  final double imageHeight;
  final _PropertyTypeOption option;

  @override
  State<_DesktopPropertyCard> createState() => _DesktopPropertyCardState();
}

class _DesktopPropertyCardState extends State<_DesktopPropertyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    final selected = widget.selected;
    final active = selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : (active ? AppColors.grey300 : AppColors.borderLight),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: active ? 0.08 : 0.04),
              blurRadius: active ? 12 : 6,
              offset: Offset(0, active ? 3 : 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: AppColors.grey50,
            splashColor: AppColors.accent.withValues(alpha: 0.1),
            highlightColor: AppColors.accent.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: widget.imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: o.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.grey100,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.grey100,
                          child: Icon(o.icon, size: 48, color: AppColors.grey400),
                        ),
                      ),
                      if (o.badge != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              o.badge!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.label,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: selected ? AppColors.accent : AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _CarouselDot extends StatelessWidget {
  const _CarouselDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.grey300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
