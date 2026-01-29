import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Ustawienia',
      currentRoute: AppRouter.dashboardSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zarządzaj kontem i preferencjami.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Konto',
            isMobile: isMobile,
            children: [
              _SettingsTile(
                icon: AppIcons.profile,
                title: 'Dane osobowe',
                subtitle: 'Imię, email, telefon',
                onTap: () {},
                isMobile: isMobile,
              ),
              _SettingsTile(
                icon: AppIcons.email,
                title: 'Adres e-mail',
                subtitle: 'Zmień adres logowania',
                onTap: () {},
                isMobile: isMobile,
              ),
              _SettingsTile(
                icon: AppIcons.phone,
                title: 'Hasło',
                subtitle: 'Zmień hasło do konta',
                onTap: () {},
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Powiadomienia',
            isMobile: isMobile,
            children: [
              _SettingsTile(
                icon: AppIcons.notifications,
                title: 'Powiadomienia e-mail',
                subtitle: 'Nowe wiadomości, zapisane wyszukiwania',
                trailing: const _SwitchTile(),
                onTap: () {},
                isMobile: isMobile,
              ),
              _SettingsTile(
                icon: AppIcons.message,
                title: 'Powiadomienia w aplikacji',
                subtitle: 'Push i powiadomienia w panelu',
                trailing: const _SwitchTile(),
                onTap: () {},
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Prywatność i bezpieczeństwo',
            isMobile: isMobile,
            children: [
              _SettingsTile(
                icon: AppIcons.security,
                title: 'Widoczność danych kontaktowych',
                subtitle: 'Kto może zobaczyć Twój numer i email',
                onTap: () {},
                isMobile: isMobile,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go(AppRouter.home),
              icon: const Icon(AppIcons.logout, size: 20, color: AppColors.error),
              label: Text(
                'Wyloguj',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.isMobile,
    required this.children,
  });

  final String title;
  final bool isMobile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.borderLight,
                    indent: isMobile ? 56 + AppSpacing.md : 64,
                    endIndent: AppSpacing.md,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isMobile,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isMobile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: AppColors.grey600, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ] else
                Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.grey400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  const _SwitchTile();

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      activeTrackColor: AppColors.accent,
    );
  }
}
