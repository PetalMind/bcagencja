import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

/// Pasek wyszukiwania: słowa kluczowe + lokalizacja (miasto, kod pocztowy, województwo).
class SearchBarCommercial extends StatefulWidget {
  final String? keyword;
  final String? location;
  final ValueChanged<String?>? onKeywordChanged;
  final ValueChanged<String?>? onLocationChanged;
  final VoidCallback? onSearch;

  const SearchBarCommercial({
    super.key,
    this.keyword,
    this.location,
    this.onKeywordChanged,
    this.onLocationChanged,
    this.onSearch,
  });

  @override
  State<SearchBarCommercial> createState() => _SearchBarCommercialState();
}

class _SearchBarCommercialState extends State<SearchBarCommercial> {
  late TextEditingController _keywordController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.keyword ?? '');
    _locationController = TextEditingController(text: widget.location ?? '');
  }

  @override
  void didUpdateWidget(SearchBarCommercial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword && _keywordController.text != widget.keyword) {
      _keywordController.text = widget.keyword ?? '';
    }
    if (oldWidget.location != widget.location && _locationController.text != widget.location) {
      _locationController.text = widget.location ?? '';
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKeywordField(),
                const SizedBox(height: AppSpacing.sm),
                _buildLocationField(),
                const SizedBox(height: AppSpacing.md),
                _buildSearchButton(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildKeywordField()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildLocationField()),
                const SizedBox(width: AppSpacing.md),
                _buildSearchButton(context),
              ],
            ),
    );
  }

  Widget _buildKeywordField() {
    return TextField(
      controller: _keywordController,
      onChanged: widget.onKeywordChanged,
      decoration: InputDecoration(
        hintText: 'Słowa kluczowe w opisach...',
        prefixIcon: const Icon(AppIcons.search, color: AppColors.grey600, size: 22),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      onSubmitted: (_) => widget.onSearch?.call(),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: _locationController,
      onChanged: widget.onLocationChanged,
      decoration: InputDecoration(
        hintText: 'Miasto, kod pocztowy, województwo...',
        prefixIcon: const Icon(AppIcons.location, color: AppColors.grey600, size: 22),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      onSubmitted: (_) => widget.onSearch?.call(),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: widget.onSearch,
      icon: const Icon(AppIcons.search, size: 20),
      label: const Text('Szukaj'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        textStyle: AppTextStyles.buttonMedium,
      ),
    );
  }
}
