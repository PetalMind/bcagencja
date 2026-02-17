import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/auth/app_user.dart';
import '../../../core/state/providers/auth_provider.dart';

/// Trzy główne kafle na stronie głównej: Inwestor, Chcę sprzedać, Kalkulator ROI.
class HomeTilesSection extends StatelessWidget {
  const HomeTilesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, AppSpacing.containerMaxWidth);
        final padding = EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
          vertical: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        );
        return Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: maxWidth,
              child: isMobile
                  ? _buildColumnLayout(context)
                  : _buildGridLayout(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeTile(
          icon: Icons.trending_up_rounded,
          title: 'Jestem Inwestorem',
          subtitle: 'Baza ofert (teasery). Logowanie (LinkedIn/NIP) → NDA → dostęp do pełnych danych i VDR.',
          ctaLabel: 'Zobacz oferty',
          onTap: () => context.go(AppRouter.oferty),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SellPropertyTile(onTap: () => context.go(AppRouter.chceSprzedac)),
        const SizedBox(height: AppSpacing.lg),
        _HomeTile(
          icon: Icons.calculate_rounded,
          title: 'Kalkulator ROI',
          subtitle: 'Oblicz stopę zwrotu i czas zwrotu – za gotówkę lub z lewarem. Na końcu zobacz oferty o podobnych parametrach.',
          ctaLabel: 'Oblicz ROI',
          onTap: () => context.go(AppRouter.kalkulatorRoi),
        ),
      ],
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    // IntrinsicHeight ensures the Row gets a bounded height when inside
    // SingleChildScrollView (which provides unbounded vertical constraints).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _HomeTile(
            icon: Icons.trending_up_rounded,
            title: 'Jestem Inwestorem',
            subtitle: 'Baza ofert (teasery). Logowanie (LinkedIn/NIP) → NDA → dostęp do pełnych danych i VDR.',
            ctaLabel: 'Zobacz oferty',
            onTap: () => context.go(AppRouter.oferty),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _SellPropertyTile(onTap: () => context.go(AppRouter.chceSprzedac)),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _HomeTile(
            icon: Icons.calculate_rounded,
            title: 'Kalkulator ROI',
            subtitle: 'Oblicz stopę zwrotu i czas zwrotu – za gotówkę lub z lewarem. Na końcu zobacz oferty o podobnych parametrach.',
            ctaLabel: 'Oblicz ROI',
            onTap: () => context.go(AppRouter.kalkulatorRoi),
          ),
        ),
      ],
      ),
    );
  }
}

/// Kafel lead magnet „Chcę sprzedać” – nagłówek pytanie, 3 korzyści, CTA, social proof.
/// Dla niezalogowanych lub niezweryfikowanych: wyszarzony + overlay z informacją i CTA „Zaloguj się”.
class _SellPropertyTile extends ConsumerWidget {
  final VoidCallback onTap;

  const _SellPropertyTile({required this.onTap});

  static bool _canAccessSell(AppUser? user) {
    return user != null && user.emailVerified;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final canAccess = _canAccessSell(user);
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    final content = Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '💰 Sprzedajesz nieruchomość komercyjną?',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          _benefit('Bezpłatna wycena w 48h'),
          const SizedBox(height: AppSpacing.xs),
          _benefit('Dostęp do sieci 500+ zweryfikowanych inwestorów'),
          const SizedBox(height: AppSpacing.xs),
          _benefit('Pełna dyskrecja i profesjonalna obsługa'),
          SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Sprawdź, ile jest warta Twoja nieruchomość',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.arrowForward,
                size: AppSpacing.iconSm,
                color: AppColors.accent,
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          Row(
            children: [
              ...List.generate(5, (_) => Icon(Icons.star_rounded, size: 14, color: AppColors.ctaHighlight)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '4.9/5 (127 sprzedanych nieruchomości)',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );

    final tileChild = canAccess
        ? content
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(_greyscaleMatrix),
            child: Opacity(
              opacity: 0.65,
              child: content,
            ),
          );

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: canAccess ? onTap : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: tileChild,
          ),
          if (!canAccess) _LockedOverlay(isMobile: isMobile),
        ],
      ),
    );
  }

  static const List<double> _greyscaleMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  static Widget _benefit(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Overlay na kafelku „Sprzedajesz” gdy użytkownik niezalogowany / niezweryfikowany.
class _LockedOverlay extends StatelessWidget {
  final bool isMobile;

  const _LockedOverlay({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // blokuje przekazanie tapu do kafelka
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: AppColors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: isMobile ? 32 : 40,
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                Text(
                  'Opcja dostępna po zalogowaniu i weryfikacji konta',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Zaloguj się lub załóż konto, zweryfikuj adres e-mail, aby skorzystać z bezpłatnej wyceny i sieci inwestorów.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () {
                    final returnTo = Uri.base.path;
                    context.push('${AppRouter.logowanie}?returnTo=${Uri.encodeComponent(returnTo)}');
                  },
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Zaloguj się'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: isMobile ? 36 : 44,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
              Row(
                children: [
                  Text(
                    ctaLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.arrowForward,
                    size: AppSpacing.iconSm,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
