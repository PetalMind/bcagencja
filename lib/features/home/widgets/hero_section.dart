import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/custom_button.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 500,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Stack(
        children: [
          // Background image with modern geometric design
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero-background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primaryDark.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryDark.withOpacity(0.3),
                    AppColors.primaryDark.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                );
                final inner = constraints.deflate(padding);
                final content = Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: inner.maxWidth.clamp(0.0, AppSpacing.containerMaxWidth),
                    maxHeight: inner.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Headline
                      Text(
                        'Nieruchomości Komercyjne i Inwestycyjne',
                        style: isMobile
                            ? AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.white,
                                fontSize: 22,
                              )
                            : AppTextStyles.displayLarge.copyWith(
                                color: AppColors.white,
                              ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                      // Subtitle
                      Text(
                        'Biura • Magazyny • Hale • Działki • Inwestycje Premium',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: isMobile ? 14 : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xxl),
                      // Search bar – ograniczona szerokość, bez overflow
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: inner.maxWidth),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: isMobile ? _buildMobileSearchForm(context) : _buildDesktopSearchForm(context),
                        ),
                      ),
                      SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                      // CTA buttons – na mobile mniejszy / ukryty w scrollu
                      if (!isMobile)
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            CustomButton(
                              label: 'Dodaj ogłoszenie',
                              icon: AppIcons.add,
                              trailingIcon: Icons.arrow_forward_rounded,
                              variant: ButtonVariant.gradient,
                              size: ButtonSize.large,
                              onPressed: () => context.go(AppRouter.addListing),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
                return SingleChildScrollView(
                  padding: padding,
                  child: isMobile
                      ? ConstrainedBox(
                          constraints: BoxConstraints(minHeight: inner.maxHeight),
                          child: content,
                        )
                      : Center(child: content),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchField({
    required IconData icon,
    required String hint,
    EdgeInsets? contentPadding,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 22),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.grey100,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  Widget _buildDesktopSearchForm(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSearchField(
            icon: AppIcons.location,
            hint: 'Lokalizacja (miasto, dzielnica)',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildSearchField(
            icon: Icons.monetization_on_rounded,
            hint: 'Cena do',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.office),
              hintText: 'Typ nieruchomości',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.grey100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'office', child: Text('Biurowiec')),
              DropdownMenuItem(value: 'warehouse', child: Text('Magazyn / Hala')),
              DropdownMenuItem(value: 'retail', child: Text('Lokal handlowy')),
              DropdownMenuItem(value: 'industrial', child: Text('Obiekt przemysłowy')),
              DropdownMenuItem(value: 'hotel', child: Text('Hotel')),
              DropdownMenuItem(value: 'land', child: Text('Działka inwestycyjna')),
            ],
            onChanged: (value) {},
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CustomButton(
          label: 'Szukaj',
          icon: AppIcons.search,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          onPressed: () => context.go(AppRouter.searchResults),
        ),
      ],
    );
  }

  Widget _buildMobileSearchForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(
          icon: AppIcons.location,
          hint: 'Lokalizacja',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSearchField(
                icon: Icons.monetization_on_rounded,
                hint: 'Cena do',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.office, size: 22),
                  hintText: 'Typ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'office', child: Text('Biurowiec')),
                  DropdownMenuItem(value: 'warehouse', child: Text('Magazyn')),
                  DropdownMenuItem(value: 'retail', child: Text('Handlowy')),
                  DropdownMenuItem(value: 'industrial', child: Text('Przemysłowy')),
                  DropdownMenuItem(value: 'land', child: Text('Działka')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Szukaj',
          icon: AppIcons.search,
          variant: ButtonVariant.primary,
          size: ButtonSize.medium,
          fullWidth: true,
          onPressed: () => context.go(AppRouter.searchResults),
        ),
      ],
    );
  }
}
