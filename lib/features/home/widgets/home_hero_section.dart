import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';

/// Hero na stronie głównej z tytułem i uproszczoną wyszukiwarką ofert.
class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key});

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  static const List<MapEntry<String, String>> _typOptions = [
    MapEntry('', 'Typ obiektu'),
    MapEntry('retail', 'Lokal handlowy'),
    MapEntry('office', 'Biurowiec'),
    MapEntry('warehouse', 'Magazyn / hala'),
    MapEntry('industrial', 'Obiekt przemysłowy'),
    MapEntry('hotel', 'Hotel'),
    MapEntry('land', 'Działka'),
    MapEntry('tenanted', 'Z najemcą'),
    MapEntry('vacant', 'Wolny'),
  ];

  static const List<String> _voivodeships = [
    'dolnośląskie', 'kujawsko-pomorskie', 'lubelskie', 'lubuskie',
    'łódzkie', 'małopolskie', 'mazowieckie', 'opolskie',
    'podkarpackie', 'podlaskie', 'pomorskie', 'śląskie',
    'świętokrzyskie', 'warmińsko-mazurskie', 'wielkopolskie', 'zachodniopomorskie',
  ];

  final _searchController = TextEditingController();
  String? _typValue;
  String? _voivodeshipValue;
  bool _searchButtonHovered = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() {
    final params = <String, String>{};
    final query = _searchController.text.trim();
    if (query.isNotEmpty) params['q'] = query;
    if (_typValue != null && _typValue!.isNotEmpty) params['typ'] = _typValue!;
    if (_voivodeshipValue != null && _voivodeshipValue!.isNotEmpty) {
      params['woj'] = _voivodeshipValue!;
    }
    final uri = Uri(
      path: AppRouter.oferty,
      queryParameters: params.isEmpty ? null : params,
    );
    if (mounted) context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nieruchomości Komercyjne i Inwestycyjne',
                style: isMobile
                    ? AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.white,
                        fontSize: 22,
                      )
                    : AppTextStyles.displaySmall.copyWith(
                        color: AppColors.white,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              Text(
                'Biura • Magazyny • Hale • Działki • Inwestycje Premium',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: isMobile ? 14 : null,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              _buildSearchCard(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile ? _buildMobileSearch(context) : _buildDesktopSearch(context),
    );
  }

  Widget _buildDesktopSearch(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Szukaj np. miasto, yield >8%, retail park...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _typValue,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
            ),
            hint: Text(
              'Typ obiektu',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            items: _typOptions
                .map((e) => DropdownMenuItem<String?>(
                      value: e.key.isEmpty ? null : e.key,
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _typValue = v),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _voivodeshipValue,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
            ),
            hint: Text(
              'Województwo',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Wszystkie', overflow: TextOverflow.ellipsis),
              ),
              ..._voivodeships.map(
                (v) => DropdownMenuItem<String?>(
                  value: v,
                  child: Text(
                    'woj. $v',
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _voivodeshipValue = v),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        MouseRegion(
          onEnter: (_) => setState(() => _searchButtonHovered = true),
          onExit: (_) => setState(() => _searchButtonHovered = false),
          child: FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              backgroundColor: _searchButtonHovered ? AppColors.primaryDark : AppColors.accent,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            child: const Text('Wyszukaj'),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearch(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Szukaj np. miasto, yield >8%...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
          onSubmitted: (_) => _apply(),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: _typValue,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
          ),
          hint: Text(
            'Typ obiektu',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          items: _typOptions
              .map((e) => DropdownMenuItem<String?>(
                    value: e.key.isEmpty ? null : e.key,
                    child: Text(
                      e.value,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _typValue = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: _voivodeshipValue,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
          ),
          hint: Text(
            'Województwo',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Wszystkie', overflow: TextOverflow.ellipsis),
            ),
            ..._voivodeships.map(
              (v) => DropdownMenuItem<String?>(
                value: v,
                child: Text(
                  'woj. $v',
                  style: AppTextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _voivodeshipValue = v),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: const Text('Wyszukaj'),
          ),
        ),
      ],
    );
  }
}
