import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image (placeholder)
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://via.placeholder.com/1920x1080?text=Beautiful+Property',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          
          // Content
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.containerMaxWidth,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Headline
                      Text(
                        'Znajdź swoje wymarzone mieszkanie',
                        style: isMobile
                            ? AppTextStyles.displaySmall.copyWith(
                                color: AppColors.white,
                              )
                            : AppTextStyles.displayLarge.copyWith(
                                color: AppColors.white,
                              ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Subtitle
                      Text(
                        'Tysiące ofert w najlepszych lokalizacjach',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Search bar
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
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
                        child: Column(
                          children: [
                            if (!isMobile)
                              Row(
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
                                        prefixIcon: const Icon(AppIcons.apartment),
                                        hintText: 'Typ nieruchomości',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm,
                                          ),
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
                                        DropdownMenuItem(
                                          value: 'apartment',
                                          child: Text('Mieszkanie'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'house',
                                          child: Text('Dom'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'land',
                                          child: Text('Działka'),
                                        ),
                                      ],
                                      onChanged: (value) {},
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ElevatedButton(
                                    onPressed: () => context.go(AppRouter.searchResults),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xl,
                                        vertical: AppSpacing.lg,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(AppIcons.search),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          'Szukaj',
                                          style: AppTextStyles.buttonMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildSearchField(
                                    icon: AppIcons.location,
                                    hint: 'Lokalizacja',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
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
                                            prefixIcon: const Icon(AppIcons.apartment),
                                            hintText: 'Typ',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusSm,
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: AppColors.grey100,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'apartment',
                                              child: Text('Mieszkanie'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'house',
                                              child: Text('Dom'),
                                            ),
                                          ],
                                          onChanged: (value) {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => context.go(AppRouter.searchResults),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(AppIcons.search),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Szukaj',
                                            style: AppTextStyles.buttonMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // CTA buttons
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go(AppRouter.addListing),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.white,
                              side: const BorderSide(color: AppColors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            child: Text(
                              'Dodaj ogłoszenie',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchField({
    required IconData icon,
    required String hint,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
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
    );
  }
}
