import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../features/dashboard/dashboard_strings.dart';
import '../../widgets/common/custom_button.dart';

/// Menu mobilne dynamiczne względem stanu auth i roli (WDROZENIE_FUNKCJONALNOSCI 4.1):
/// - Anonim: Zaloguj, bez "Dodaj ogłoszenie", bez Panelu/Ulubione.
/// - Zalogowany (lead): Panel, Ulubione, Wyloguj, bez "Dodaj ogłoszenie".
/// - Zalogowany (agent/dyrektor/admin): Panel, Ulubione, "Dodaj ogłoszenie", Wyloguj.
class MobileMenu extends ConsumerWidget {
  const MobileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final isLoggedIn = user != null;
    final showAddListing = isLoggedIn && (user?.hasPartnerDashboard ?? false);
    final showVerifyAccount = isLoggedIn && (user?.hasIdentityVerifiedAccess != true);
    final auth = ref.read(authServiceProvider);

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.primaryDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _buildMenuItem(
                    context,
                    icon: AppIcons.home,
                    title: 'Strona główna',
                    onTap: () {
                      context.go(AppRouter.home);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.search,
                    title: 'Wyszukiwarka',
                    onTap: () {
                      context.go(AppRouter.search);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.office,
                    title: 'Oferty komercyjne',
                    onTap: () {
                      context.go(AppRouter.oferty);
                      Navigator.of(context).pop();
                    },
                  ),
                  if (showVerifyAccount)
                    _buildMenuItem(
                      context,
                      icon: Icons.verified_user_outlined,
                      title: 'Zweryfikuj konto',
                      onTap: () {
                        context.go(AppRouter.weryfikacja);
                        Navigator.of(context).pop();
                      },
                      highlighted: true,
                    ),
                  if (isLoggedIn)
                    _buildMenuItem(
                      context,
                      icon: AppIcons.login,
                      title: 'Wyloguj',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await auth.signOut();
                        if (context.mounted) context.go(AppRouter.home);
                      },
                    )
                  else
                    _buildMenuItem(
                      context,
                      icon: AppIcons.login,
                      title: 'Zaloguj',
                      onTap: () {
                        context.go(AppRouter.logowanie);
                        Navigator.of(context).pop();
                      },
                    ),
                  if (showAddListing) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: CustomButton(
                        label: 'Dodaj ogłoszenie',
                        icon: AppIcons.add,
                        variant: ButtonVariant.gradient,
                        size: ButtonSize.medium,
                        fullWidth: true,
                        onPressed: () {
                          context.go(AppRouter.chceSprzedac);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                  if (isLoggedIn) ...[
                    const Divider(),
                    _buildMenuItem(
                      context,
                      icon: AppIcons.profile,
                      title: DashboardStrings.titleShort,
                      onTap: () {
                        context.go(AppRouter.dashboard);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: AppIcons.search,
                      title: 'Przeglądaj oferty',
                      onTap: () {
                        context.go(AppRouter.oferty);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: AppIcons.favorites,
                      title: 'Ulubione',
                      onTap: () {
                        context.go(AppRouter.dashboardFavorites);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.real_estate_agent_outlined,
                      title: 'Moje zgłoszenia',
                      onTap: () {
                        context.go(AppRouter.dashboardMySubmissions);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.info,
                    title: 'O nas',
                    onTap: () {
                      context.go(AppRouter.about);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.article_rounded,
                    title: 'Blog',
                    onTap: () {
                      context.go(AppRouter.blog);
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: AppIcons.email,
                    title: 'Kontakt',
                    onTap: () {
                      context.go(AppRouter.contact);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: highlighted ? AppColors.accent : AppColors.grey600,
        size: AppSpacing.iconMd,
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: highlighted ? AppColors.accent : AppColors.textPrimary,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: highlighted ? AppColors.accent.withOpacity(0.05) : null,
    );
  }
}
