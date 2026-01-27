import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    final testimonials = [
      {
        'name': 'Anna Kowalska',
        'text':
            'Dzięki BC Agencja znalazłam wymarzone mieszkanie w centrum Warszawy. Proces był szybki i bezproblemowy!',
        'rating': 5,
      },
      {
        'name': 'Piotr Nowak',
        'text':
            'Profesjonalna obsługa i szeroki wybór ofert. Polecam każdemu, kto szuka nieruchomości.',
        'rating': 5,
      },
      {
        'name': 'Maria Wiśniewska',
        'text':
            'Łatwy w użyciu portal z doskonałymi filtrami wyszukiwania. Znalazłam dom marzeń!',
        'rating': 5,
      },
    ];
    
    return Container(
      width: double.infinity,
      color: AppColors.backgroundGrey,
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
            children: [
              Text(
                'Co mówią nasi klienci',
                style: isMobile
                    ? AppTextStyles.headlineMedium
                    : AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: testimonials.map((testimonial) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _buildTestimonialCard(testimonial),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: testimonials.map((testimonial) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildTestimonialCard(testimonial),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTestimonialCard(Map<String, dynamic> testimonial) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating
            Row(
              children: List.generate(
                testimonial['rating'] as int,
                (index) => const Icon(
                  AppIcons.star,
                  color: AppColors.warning,
                  size: AppSpacing.iconSm,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Text
            Text(
              testimonial['text'] as String,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Name
            Text(
              testimonial['name'] as String,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
