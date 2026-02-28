import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';

/// Pasek wyszukiwania ofert: pole tekstowe, filtry Typ, Yield, Woj., Najemca, Cena, Powierzchnia.
class ListingsSearchBar extends StatefulWidget {
  const ListingsSearchBar({
    super.key,
    this.searchQuery,
    this.cenaMin,
    this.cenaMax,
    this.areaMin,
    this.areaMax,
    this.typFilter,
    this.roiMin,
    this.voivodeship,
    this.tenant,
  });

  final String? searchQuery;
  final String? cenaMin;
  final String? cenaMax;
  final String? areaMin;
  final String? areaMax;
  final String? typFilter;
  final String? roiMin;
  final String? voivodeship;
  final String? tenant;

  @override
  State<ListingsSearchBar> createState() => _ListingsSearchBarState();
}

class _ListingsSearchBarState extends State<ListingsSearchBar> {
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
  final _cenaMinController = TextEditingController();
  final _cenaMaxController = TextEditingController();
  final _areaMinController = TextEditingController();
  final _areaMaxController = TextEditingController();
  final _roiMinController = TextEditingController();
  final _tenantController = TextEditingController();

  String? _typValue;
  String? _voivodeshipValue;
  bool _cenaExpanded = false;
  bool _powierzchniaExpanded = false;
  bool _searchButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    _cenaMinController.text = widget.cenaMin ?? '';
    _cenaMaxController.text = widget.cenaMax ?? '';
    _areaMinController.text = widget.areaMin ?? '';
    _areaMaxController.text = widget.areaMax ?? '';
    _roiMinController.text = widget.roiMin ?? '';
    _tenantController.text = widget.tenant ?? '';
    _typValue = widget.typFilter;
    _voivodeshipValue = widget.voivodeship;
  }

  @override
  void didUpdateWidget(ListingsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.cenaMin != widget.cenaMin ||
        oldWidget.cenaMax != widget.cenaMax ||
        oldWidget.areaMin != widget.areaMin ||
        oldWidget.areaMax != widget.areaMax ||
        oldWidget.typFilter != widget.typFilter ||
        oldWidget.roiMin != widget.roiMin ||
        oldWidget.voivodeship != widget.voivodeship ||
        oldWidget.tenant != widget.tenant) {
      _searchController.text = widget.searchQuery ?? '';
      _cenaMinController.text = widget.cenaMin ?? '';
      _cenaMaxController.text = widget.cenaMax ?? '';
      _areaMinController.text = widget.areaMin ?? '';
      _areaMaxController.text = widget.areaMax ?? '';
      _roiMinController.text = widget.roiMin ?? '';
      _tenantController.text = widget.tenant ?? '';
      _typValue = widget.typFilter;
      _voivodeshipValue = widget.voivodeship;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cenaMinController.dispose();
    _cenaMaxController.dispose();
    _areaMinController.dispose();
    _areaMaxController.dispose();
    _roiMinController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  void _apply() {
    final params = <String, String>{};
    final query = _searchController.text.trim();
    if (query.isNotEmpty) params['q'] = query;
    if (_cenaMinController.text.trim().isNotEmpty) params['cenaMin'] = _cenaMinController.text.trim();
    if (_cenaMaxController.text.trim().isNotEmpty) params['cenaMax'] = _cenaMaxController.text.trim();
    if (_areaMinController.text.trim().isNotEmpty) params['areaMin'] = _areaMinController.text.trim();
    if (_areaMaxController.text.trim().isNotEmpty) params['areaMax'] = _areaMaxController.text.trim();
    if (_typValue != null && _typValue!.isNotEmpty) params['typ'] = _typValue!;
    if (_roiMinController.text.trim().isNotEmpty) params['roiMin'] = _roiMinController.text.trim();
    if (_voivodeshipValue != null && _voivodeshipValue!.isNotEmpty) params['woj'] = _voivodeshipValue!;
    if (_tenantController.text.trim().isNotEmpty) params['tenant'] = _tenantController.text.trim();
    final uri = Uri(path: AppRouter.oferty, queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  String _cenaLabel() {
    final min = _cenaMinController.text.trim();
    final max = _cenaMaxController.text.trim();
    if (min.isEmpty && max.isEmpty) return 'Cena';
    if (min.isNotEmpty && max.isNotEmpty) return '$min – $max zł';
    if (min.isNotEmpty) return 'od $min zł';
    return 'do $max zł';
  }

  String _powierzchniaLabel() {
    final min = _areaMinController.text.trim();
    final max = _areaMaxController.text.trim();
    if (min.isEmpty && max.isEmpty) return 'Powierzchnia';
    if (min.isNotEmpty && max.isNotEmpty) return '$min – $max m²';
    if (min.isNotEmpty) return 'od $min m²';
    return 'do $max m²';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Szukaj np. yield >8%, retail park, Lidl, miasto...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildFilterDropdown(
          label: _cenaLabel(),
          expanded: _cenaExpanded,
          onTap: () => setState(() {
            _cenaExpanded = !_cenaExpanded;
            if (_cenaExpanded) _powierzchniaExpanded = false;
          }),
          content: _buildCenaFields(),
        )),
        Container(width: 1, height: 40, color: AppColors.borderLight),
        Expanded(child: _buildFilterDropdown(
          label: _powierzchniaLabel(),
          expanded: _powierzchniaExpanded,
          onTap: () => setState(() {
            _powierzchniaExpanded = !_powierzchniaExpanded;
            if (_powierzchniaExpanded) _cenaExpanded = false;
          }),
          content: _buildPowierzchniaFields(),
        )),
        const SizedBox(width: AppSpacing.md),
        MouseRegion(
          onEnter: (_) => setState(() => _searchButtonHovered = true),
          onExit: (_) => setState(() => _searchButtonHovered = false),
          child: FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              backgroundColor: _searchButtonHovered ? AppColors.primaryDark : AppColors.accent,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
            child: const Text('Wyszukaj'),
          ),
        ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildFilterChips(isMobile: false),
      ],
    );
  }

  Widget _buildFilterChips({required bool isMobile}) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<String?>(
          offset: const Offset(0, 40),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            setState(() => _typValue = v);
            _apply();
          },
          itemBuilder: (ctx) => _typOptions
              .map((e) => PopupMenuItem<String?>(
                    value: e.key.isEmpty ? null : e.key,
                    child: Row(
                      children: [
                        Icon(Icons.apartment_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(e.value),
                      ],
                    ),
                  ))
              .toList(),
          child: _FilterChipLabel(
            icon: Icons.apartment_rounded,
            label: _typValue == null || _typValue!.isEmpty
                ? 'Typ obiektu'
                : _typOptions.firstWhere((e) => e.key == _typValue, orElse: () => _typOptions.first).value,
            isActive: _typValue != null && _typValue!.isNotEmpty,
          ),
        ),
        _FilterChipInput(
          icon: Icons.trending_up_rounded,
          label: 'Yield min',
          controller: _roiMinController,
          suffix: '%',
          onChanged: () => _apply(),
        ),
        PopupMenuButton<String?>(
          offset: const Offset(0, 40),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            setState(() => _voivodeshipValue = v);
            _apply();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: null, child: Text('Wszystkie')),
            ..._voivodeships.map((v) => PopupMenuItem<String?>(
                  value: v,
                  child: Row(
                    children: [
                      Icon(Icons.map_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('woj. $v'),
                    ],
                  ),
                )),
          ],
          child: _FilterChipLabel(
            icon: Icons.map_rounded,
            label: _voivodeshipValue == null || _voivodeshipValue!.isEmpty
                ? 'Województwo'
                : 'woj. $_voivodeshipValue',
            isActive: _voivodeshipValue != null && _voivodeshipValue!.isNotEmpty,
          ),
        ),
        _FilterChipInput(
          icon: Icons.store_rounded,
          label: 'Najemca',
          controller: _tenantController,
          onChanged: () => _apply(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Szukaj np. yield >8%, retail park, Lidl, miasto...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
          onSubmitted: (_) => _apply(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildFilterDropdown(
          label: _cenaLabel(),
          expanded: _cenaExpanded,
          onTap: () => setState(() {
            _cenaExpanded = !_cenaExpanded;
            if (_cenaExpanded) _powierzchniaExpanded = false;
          }),
          content: _buildCenaFields(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildFilterDropdown(
          label: _powierzchniaLabel(),
          expanded: _powierzchniaExpanded,
          onTap: () => setState(() {
            _powierzchniaExpanded = !_powierzchniaExpanded;
            if (_powierzchniaExpanded) _cenaExpanded = false;
          }),
          content: _buildPowierzchniaFields(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildFilterChips(isMobile: true),
        const SizedBox(height: AppSpacing.md),
        MouseRegion(
          onEnter: (_) => setState(() => _searchButtonHovered = true),
          onExit: (_) => setState(() => _searchButtonHovered = false),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: _searchButtonHovered ? AppColors.primaryDark : AppColors.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text('Wyszukaj'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required bool expanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: expanded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.sm, right: AppSpacing.sm, bottom: AppSpacing.xs),
            child: content,
          ),
        ],
      ],
    );
  }

  Widget _buildCenaFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cenaMinController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'od',
              suffixText: 'zł',
              suffixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _cenaMaxController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'do',
              suffixText: 'zł',
              suffixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPowierzchniaFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _areaMinController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: 'od',
              suffixText: 'm²',
              suffixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _areaMaxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: 'do',
              suffixText: 'm²',
              suffixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent.withValues(alpha: 0.12) : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isActive ? AppColors.accent : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? AppColors.accent : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _FilterChipInput extends StatelessWidget {
  const _FilterChipInput({
    required this.icon,
    required this.label,
    required this.controller,
    this.suffix,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? suffix;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    return Container(
      width: suffix != null ? 95 : 130,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: hasValue ? AppColors.accent.withValues(alpha: 0.12) : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: hasValue ? AppColors.accent : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: hasValue ? AppColors.accent : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: suffix != null
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: suffix != null
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                  : null,
              decoration: InputDecoration(
                hintText: label,
                suffixText: suffix,
                suffixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
