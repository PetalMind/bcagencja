import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/router/app_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';

/// Makieta strony bloga – lista wpisów o nieruchomościach i rynku.
class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  static const List<Map<String, String>> _posts = [
    {
      'title': 'Rynek magazynów w 2025 – gdzie szukać powierzchni',
      'excerpt': 'Przegląd najważniejszych lokalizacji pod powierzchnie magazynowe i logistyczne w Polsce.',
      'date': '28.01.2025',
      'category': 'Rynek',
    },
    {
      'title': 'Biura klasy A – na co zwracać uwagę przy wynajmie',
      'excerpt': 'Standardy budynków biurowych, certyfikaty i praktyczne wskazówki dla firm.',
      'date': '22.01.2025',
      'category': 'Poradnik',
    },
    {
      'title': 'Działki inwestycyjne pod projekty mieszkaniowe',
      'excerpt': 'Jak wybrać działkę pod deweloperkę i na co zwrócić uwagę w dokumentacji.',
      'date': '15.01.2025',
      'category': 'Inwestycje',
    },
    {
      'title': 'Hale przemysłowe – wymagania i koszty adaptacji',
      'excerpt': 'Przegląd norm, mediów i typowych prac przy zakupie hali pod produkcję.',
      'date': '08.01.2025',
      'category': 'Poradnik',
    },
    {
      'title': 'Wynajem lokali handlowych w centrum miasta',
      'excerpt': 'Footfall, umowy najmu i klauzule dostosowane do handlu detalicznego.',
      'date': '02.01.2025',
      'category': 'Rynek',
    },
    {
      'title': 'Nieruchomości komercyjne a zmiany w prawie w 2025',
      'excerpt': 'Podsumowanie nowelizacji ustaw wpływających na transakcje komercyjne.',
      'date': '28.12.2024',
      'category': 'Prawo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BlogHero(isMobile: isMobile),
            _BlogPostsList(isMobile: isMobile, posts: _posts),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }
}

class _BlogHero extends StatelessWidget {
  final bool isMobile;

  const _BlogHero({required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              Text(
                'Blog',
                style: (isMobile
                        ? AppTextStyles.headlineLarge
                        : AppTextStyles.displaySmall)
                    .copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Poradniki, analizy rynku i aktualności o nieruchomościach komercyjnych',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogPostsList extends StatelessWidget {
  final bool isMobile;
  final List<Map<String, String>> posts;

  const _BlogPostsList({
    required this.isMobile,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Najnowsze wpisy',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),
              isMobile
                  ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _BlogPostCard(
                        post: posts[index],
                        isMobile: isMobile,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const crossAxisCount = 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: AppSpacing.lg,
                            crossAxisSpacing: AppSpacing.lg,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) => _BlogPostCard(
                            post: posts[index],
                            isMobile: isMobile,
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogPostCard extends StatelessWidget {
  final Map<String, String> post;
  final bool isMobile;

  const _BlogPostCard({
    required this.post,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  post['category']!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                AppIcons.edit,
                size: AppSpacing.iconXs,
                color: AppColors.grey400,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                post['date']!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            post['title']!,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            post['excerpt']!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            maxLines: isMobile ? 3 : 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Czytaj więcej',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.arrowForward,
                size: AppSpacing.iconXs,
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
