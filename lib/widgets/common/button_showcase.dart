import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_colors.dart';
import 'custom_button.dart';
import 'shimmer_button.dart';

/// Showcase widget demonstrating all button variants and sizes
/// Use this as a reference for implementing buttons across the app
class ButtonShowcase extends StatelessWidget {
  const ButtonShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Button Showcase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Button Variants', style: AppTextStyles.displaySmall),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Modern, reusable buttons with geometric design elements matching the hero section style',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Primary Buttons
            _buildSection(
              'Primary Buttons',
              'Main call-to-action buttons with geometric hover effects',
              [
                CustomButton(
                  label: 'Szukaj nieruchomości',
                  icon: AppIcons.search,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Kontakt',
                  icon: AppIcons.phone,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Zapisz',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.small,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Gradient Buttons
            _buildSection(
              'Gradient Buttons',
              'Premium buttons with animated geometric backgrounds',
              [
                CustomButton(
                  label: 'Dodaj ogłoszenie',
                  icon: AppIcons.add,
                  variant: ButtonVariant.gradient,
                  size: ButtonSize.large,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Inwestuj teraz',
                  trailingIcon: Icons.arrow_forward_rounded,
                  variant: ButtonVariant.gradient,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Secondary Buttons
            _buildSection(
              'Secondary Buttons',
              'Alternative action buttons',
              [
                CustomButton(
                  label: 'Więcej informacji',
                  icon: AppIcons.info,
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.large,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Pokaż szczegóły',
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Outlined Buttons
            _buildSection(
              'Outlined Buttons',
              'Subtle action buttons with hover effects',
              [
                CustomButton(
                  label: 'Zapisz do ulubionych',
                  icon: AppIcons.favorites,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.large,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Udostępnij',
                  icon: AppIcons.share,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Anuluj',
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Text Buttons
            _buildSection(
              'Text Buttons',
              'Minimal buttons for tertiary actions',
              [
                CustomButton(
                  label: 'Dowiedz się więcej',
                  trailingIcon: Icons.arrow_forward_rounded,
                  variant: ButtonVariant.text,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                CustomButton(
                  label: 'Pomiń',
                  variant: ButtonVariant.text,
                  size: ButtonSize.medium,
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // States
            _buildSection(
              'Button States',
              'Loading and disabled states',
              [
                CustomButton(
                  label: 'Loading...',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  isLoading: true,
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                const CustomButton(
                  label: 'Disabled',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  onPressed: null,
                ),
                const SizedBox(width: AppSpacing.md),
                const CustomButton(
                  label: 'Disabled Outlined',
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.medium,
                  onPressed: null,
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Shimmer Buttons - Premium Effects
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shimmer Effects - Premium CTAs',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Luksusowe efekty shimmer/shine dla najważniejszych przycisków',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey300,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      ShimmerButton(
                        label: 'Metallic Shine',
                        icon: AppIcons.star,
                        variant: ShimmerVariant.metallic,
                        onPressed: () {},
                      ),
                      ShimmerButton(
                        label: 'Holographic',
                        icon: Icons.auto_awesome_rounded,
                        variant: ShimmerVariant.holographic,
                        onPressed: () {},
                      ),
                      ShimmerButton(
                        label: 'Premium Gold',
                        icon: Icons.diamond_rounded,
                        variant: ShimmerVariant.premium,
                        onPressed: () {},
                      ),
                      ShimmerButton(
                        label: 'Neon Glow',
                        icon: Icons.flash_on_rounded,
                        variant: ShimmerVariant.neon,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  ShimmerButton(
                    label: 'Zobacz ekskluzywne oferty',
                    icon: AppIcons.star,
                    trailingIcon: Icons.arrow_forward_rounded,
                    variant: ShimmerVariant.premium,
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Full Width
            _buildSection(
              'Full Width Buttons',
              'Buttons that span the full container width',
              [
                CustomButton(
                  label: 'Wyślij zapytanie',
                  icon: AppIcons.message,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                  fullWidth: true,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Umów wizytę',
                  icon: AppIcons.calendar,
                  variant: ButtonVariant.gradient,
                  size: ButtonSize.large,
                  fullWidth: true,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: buttons,
        ),
      ],
    );
  }
}
