import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/custom_button.dart';
import '../../listings/widgets/listing_grid_tile.dart';

class LatestListings extends StatelessWidget {
  const LatestListings({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    final isTablet = screenWidth >= AppSpacing.mobileBreakpoint &&
        screenWidth < AppSpacing.tabletBreakpoint;

    // Mock latest properties
    final latestProperties = List.generate(8, (i) => Property.mock(i + 3));

    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    // Na mobile wyższe karty (mniejszy ratio) – więcej miejsca na tekst, mniej overflow
    final childAspectRatio = isMobile ? 0.68 : 0.75;

    return Container(
      width: double.infinity,
      color: AppColors.backgroundGrey,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Najnowsze ogłoszenia',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomButton(
                      label: 'Zobacz wszystkie',
                      trailingIcon: Icons.arrow_forward_rounded,
                      variant: ButtonVariant.text,
                      size: ButtonSize.medium,
                      onPressed: () => context.go(AppRouter.searchResults),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Najnowsze ogłoszenia',
                      style: AppTextStyles.headlineLarge,
                    ),
                    CustomButton(
                      label: 'Zobacz wszystkie',
                      trailingIcon: Icons.arrow_forward_rounded,
                      variant: ButtonVariant.text,
                      size: ButtonSize.medium,
                      onPressed: () => context.go(AppRouter.searchResults),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: latestProperties.length,
                itemBuilder: (context, index) {
                  return ListingGridTile(property: latestProperties[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
