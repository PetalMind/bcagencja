import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/layout/scaffold_with_sidebar.dart';

/// Topbar dynamiczny względem stanu auth i roli użytkownika (WDROZENIE_FUNKCJONALNOSCI 4.1):
/// - Anonim: Zaloguj, bez "Dodaj ogłoszenie", bez Panelu.
/// - Zalogowany (lead): Panel, Wyloguj, bez "Dodaj ogłoszenie".
/// - Zalogowany (agent/dyrektor/admin): Panel, "Dodaj ogłoszenie", Wyloguj.
class AppBarCustom extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBackButton;
  /// Gdy ustawiony, wyświetlany zamiast "BC Agencja" (np. tytuł podstrony dashboardu).
  final String? title;
  /// Gdy ustawiony przy showBackButton, wywoływany zamiast context.pop() (np. powrót do dashboardu).
  final VoidCallback? onBackPressed;
  /// Pełne nadpisanie akcji (gdy ustawione, ignoruje actionsPrepend i domyślne).
  final List<Widget>? actions;
  /// Akcje dodawane na początku przed domyślnymi (Edytuj itd.).
  final List<Widget>? actionsPrepend;

  const AppBarCustom({
    super.key,
    this.showBackButton = false,
    this.title,
    this.onBackPressed,
    this.actions,
    this.actionsPrepend,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.valueOrNull;
    final isLoggedIn = user != null;
    final authLoading = asyncUser.isLoading;
    final showAddListing = isLoggedIn && user.hasPartnerDashboard;
    final showVerifyAccount = isLoggedIn && (user.hasIdentityVerifiedAccess != true);

    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: onBackPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRouter.home);
                    }
                  },
            )
          : isMobile
              ? Builder(
                  builder: (context) {
                    final openDrawer = SidebarShellScope.maybeOpenDrawerOf(context);
                    return IconButton(
                      icon: const Icon(AppIcons.menu),
                      onPressed: openDrawer ?? () => Scaffold.of(context).openDrawer(),
                    );
                  },
                )
              : null,
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.white,
              ),
            )
          : GestureDetector(
              onTap: () => context.go(AppRouter.home),
              child: Text(
                'BC Agencja',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
      actions: actions ??
          [
            ...?actionsPrepend,
            ..._buildDefaultActions(context, ref, isMobile, isLoggedIn, authLoading, showAddListing, showVerifyAccount),
          ],
    );
  }

  List<Widget> _buildDefaultActions(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
    bool isLoggedIn,
    bool authLoading,
    bool showAddListing,
    bool showVerifyAccount,
  ) {
    final auth = ref.read(authServiceProvider);
    return [
      if (!isMobile && !isLoggedIn) ...[
        TextButton(
          onPressed: () => context.go(AppRouter.search),
          child: Text(
            'Szukaj',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.about),
          child: Text(
            'O nas',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.blog),
          child: Text(
            'Blog',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRouter.contact),
          child: Text(
            'Kontakt',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      if (showVerifyAccount)
        TextButton(
          onPressed: () => context.go(AppRouter.weryfikacja),
          child: Text(
            'Zweryfikuj konto',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
      if (authLoading)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: SizedBox(
            width: 56,
            height: 36,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        )
      else if (isLoggedIn)
        const SizedBox.shrink()
      else
        TextButton(
          onPressed: () => context.go(AppRouter.logowanie),
          child: Text(
            'Zaloguj',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
      const SizedBox(width: AppSpacing.xs),
      if (showAddListing) ...[
        if (isMobile)
          IconButton(
            icon: const Icon(AppIcons.add),
            onPressed: () => context.go(AppRouter.chceSprzedac),
            tooltip: 'Dodaj ogłoszenie',
          )
        else
          CustomButton(
            label: 'Dodaj ogłoszenie',
            icon: AppIcons.add,
            variant: ButtonVariant.gradient,
            size: ButtonSize.medium,
            onPressed: () => context.go(AppRouter.chceSprzedac),
          ),
        const SizedBox(width: AppSpacing.sm),
      ],
      if (isLoggedIn)
        _UserMenuButton(auth: auth),
      const SizedBox(width: AppSpacing.sm),
    ];
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppColors.white,
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            context.go(AppRouter.dashboard);
            break;
          case 'settings':
            context.go(AppRouter.dashboardSettings);
            break;
          case 'logout':
            await auth.signOut();
            if (context.mounted) context.go(AppRouter.home);
            break;
        }
      },
      icon: const Icon(AppIcons.profile, color: AppColors.white),
      tooltip: 'Menu użytkownika',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(AppIcons.profile, size: 20),
            title: Text('Panel'),
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(AppIcons.settings, size: 20),
            title: Text('Ustawienia'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(AppIcons.logout, size: 20, color: AppColors.error),
            title: Text('Wyloguj', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ],
    );
  }
}
