import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

/// Pokazuje lightbox galerii. Używane na stronie szczegółów i z kart listingu.
void showGalleryLightbox(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
  List<String>? captions,
}) {
  if (images.isEmpty) return;
  final safeIndex = initialIndex.clamp(0, images.length - 1);
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.black.withValues(alpha: 0.87),
    builder: (dialogContext) => GalleryLightboxDialog(
      images: images,
      initialIndex: safeIndex,
      captions: captions,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class PropertyGallery extends StatefulWidget {
  final List<String> images;
  final List<String>? captions;

  const PropertyGallery({
    super.key,
    required this.images,
    this.captions,
  });

  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<PropertyGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  int get _safeIndex =>
      widget.images.isEmpty ? 0 : _currentIndex.clamp(0, widget.images.length - 1);

  bool get _hasMultiple => widget.images.length > 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(PropertyGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      _currentIndex = _safeIndex;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showLightbox(BuildContext context) {
    if (widget.images.isEmpty) return;
    showGalleryLightbox(
      context,
      images: widget.images,
      initialIndex: _safeIndex,
      captions: widget.captions,
    );
    setState(() => _currentIndex = _safeIndex);
  }

  double _mainImageHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppSpacing.mobileBreakpoint) return 250;
    if (width < AppSpacing.tabletBreakpoint) return 320;
    return 400;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyPlaceholder(context);
    }

    return Column(
      children: [
        _buildMainImage(context),
        if (_hasMultiple) ...[
          const SizedBox(height: AppSpacing.md),
          _buildThumbnails(context),
        ],
      ],
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final height = _mainImageHeight(context);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.image, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Brak zdjęć',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    final height = _mainImageHeight(context);
    final imageUrl = widget.images[_safeIndex];

    return Semantics(
      label: 'Zdjęcie ${_safeIndex + 1} z ${widget.images.length}. Dotknij, aby powiększyć.',
      button: true,
      child: GestureDetector(
        onTap: _hasMultiple ? () => _showLightbox(context) : () => _showLightbox(context),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: _hasMultiple
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index.clamp(0, widget.images.length - 1)),
                    itemBuilder: (context, index) => _buildCachedImage(
                      widget.images[index],
                      fit: BoxFit.cover,
                      showLoading: true,
                    ),
                  )
                : _buildCachedImage(imageUrl, fit: BoxFit.cover, showLoading: true),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnails(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final isSelected = index == _safeIndex;
          return Semantics(
            label: 'Pokaż zdjęcie ${index + 1}',
            button: true,
            child: GestureDetector(
              onTap: () {
                setState(() => _currentIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: _buildCachedImage(widget.images[index], fit: BoxFit.cover),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCachedImage(
    String url, {
    required BoxFit fit,
    bool showLoading = false,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: showLoading
          ? (_, _) => Container(
                color: AppColors.grey200,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              )
          : null,
      errorWidget: (_, _, _) => Icon(
        AppIcons.image,
        size: 48,
        color: AppColors.grey400,
      ),
    );
  }
}

/// Dialog lightbox z przewijaniem, zoomem i opcjonalnymi opisami.
class GalleryLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final List<String>? captions;
  final VoidCallback onClose;

  const GalleryLightboxDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    this.captions,
    required this.onClose,
  });

  @override
  State<GalleryLightboxDialog> createState() => _GalleryLightboxDialogState();
}

class _GalleryLightboxDialogState extends State<GalleryLightboxDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex--);
    }
  }

  void _goNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex++);
    }
  }

  String? get _currentCaption {
    if (widget.captions == null || widget.captions!.length <= _currentIndex) return null;
    final c = widget.captions![_currentIndex].trim();
    return c.isEmpty ? null : c;
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.images.length > 1;
    return Dialog(
      backgroundColor: AppColors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index.clamp(0, widget.images.length - 1)),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(color: AppColors.white),
                      ),
                      errorWidget: (_, _, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            AppIcons.error,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Nie udało się załadować',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: AppSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: IconButton(
                  icon: const Icon(AppIcons.close, color: AppColors.white, size: 28),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (hasMultiple && _currentIndex > 0)
                Positioned(
                  left: AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        AppIcons.chevronLeft,
                        color: AppColors.white,
                        size: 48,
                      ),
                      onPressed: _goPrev,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              if (hasMultiple && _currentIndex < widget.images.length - 1)
                Positioned(
                  right: AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        AppIcons.chevronRight,
                        color: AppColors.white,
                        size: 48,
                      ),
                      onPressed: _goNext,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              if (_currentCaption != null)
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        _currentCaption!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ),
              ),
            ],
      ),
    );
  }
}
