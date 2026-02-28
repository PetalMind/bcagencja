import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';

/// Sekcja „Popularne lokalizacje” – chipy z miastami i regionami (linki do wyszukiwania).
class HomeLocationsSection extends StatefulWidget {
  const HomeLocationsSection({super.key});

  @override
  State<HomeLocationsSection> createState() => _HomeLocationsSectionState();
}

class _LocationChip {
  const _LocationChip({required this.label, required this.queryParam, this.isVoivodeship = false});
  final String label;
  final String queryParam;
  final bool isVoivodeship;
}

class _HomeLocationsSectionState extends State<HomeLocationsSection> {
  static const List<_LocationChip> _locations = [
    _LocationChip(label: 'Warszawa', queryParam: 'Warszawa'),
    _LocationChip(label: 'Kraków', queryParam: 'Kraków'),
    _LocationChip(label: 'Wrocław', queryParam: 'Wrocław'),
    _LocationChip(label: 'Poznań', queryParam: 'Poznań'),
    _LocationChip(label: 'Gdańsk', queryParam: 'Gdańsk'),
    _LocationChip(label: 'Łódź', queryParam: 'Łódź'),
    _LocationChip(label: 'Katowice', queryParam: 'Katowice'),
    _LocationChip(label: 'Śląsk', queryParam: 'śląskie', isVoivodeship: true),
    _LocationChip(label: 'Mazowsze', queryParam: 'mazowieckie', isVoivodeship: true),
    _LocationChip(label: 'Dolny Śląsk', queryParam: 'dolnośląskie', isVoivodeship: true),
    _LocationChip(label: 'Pomorze', queryParam: 'pomorskie', isVoivodeship: true),
    _LocationChip(label: 'Wielkopolska', queryParam: 'wielkopolskie', isVoivodeship: true),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      color: AppColors.grey50,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popularne lokalizacje',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _locations
                    .map(
                      (loc) => _LocationChipTile(
                        label: loc.label,
                        onTap: () {
                          final params = loc.isVoivodeship
                              ? {'woj': loc.queryParam}
                              : {'q': loc.queryParam};
                          final uri = Uri(path: AppRouter.oferty, queryParameters: params);
                          context.go(uri.toString());
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationChipTile extends StatefulWidget {
  const _LocationChipTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_LocationChipTile> createState() => _LocationChipTileState();
}

class _LocationChipTileState extends State<_LocationChipTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        elevation: 1,
        shadowColor: AppColors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          hoverColor: AppColors.accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _hovered ? AppColors.accent : AppColors.borderLight,
                width: _hovered ? 2 : 1,
              ),
            ),
            child: Text(
              widget.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _hovered ? AppColors.accent : AppColors.primaryDark,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
