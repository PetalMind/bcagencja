import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';

/// Stopka aplikacji – ciemne tło, kolumny: logo/opis, nawigacja, kontakt, prawne.
class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.xl : AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidth),
          child: Column(
            children: [
              isMobile ? _buildMobileColumns(context) : _buildDesktopColumns(context),
              const SizedBox(height: AppSpacing.xl),
              Divider(color: AppColors.white.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '© ${DateTime.now().year} ${AppConfig.appName}. Wszelkie prawa zastrzeżone.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopColumns(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.appName,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nieruchomości komercyjne i inwestycyjne – biura, magazyny, lokale handlowe, działki. '
                'Bezpłatna wycena, sieć inwestorów, pełna dyskrecja.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        Expanded(
          child: _FooterColumn(
            title: 'Nawigacja',
            links: [
              _FooterLink(label: 'Oferty', onTap: () => context.go(AppRouter.oferty)),
              _FooterLink(label: 'Kalkulator ROI', onTap: () => context.go(AppRouter.kalkulatorRoi)),
              _FooterLink(label: 'Chcę sprzedać', onTap: () => context.go(AppRouter.chceSprzedac)),
              _FooterLink(label: 'O nas', onTap: () => context.go(AppRouter.about)),
              _FooterLink(label: 'Kontakt', onTap: () => context.go(AppRouter.contact)),
            ],
          ),
        ),
        Expanded(
          child: _FooterColumn(
            title: 'Kontakt',
            children: [
              _FooterContactRow(
                icon: Icons.email_outlined,
                label: AppConfig.contactEmail,
                onTap: () => _launchMailto(AppConfig.contactEmail),
              ),
              const SizedBox(height: AppSpacing.sm),
              _FooterContactRow(
                icon: Icons.phone_outlined,
                label: AppConfig.supportPhone,
                onTap: () => _launchTel(AppConfig.supportPhone),
              ),
            ],
          ),
        ),
        Expanded(
          child: _FooterColumn(
            title: 'Prawne',
            links: [
              _FooterLink(
                label: 'Polityka prywatności',
                onTap: () => context.go(AppRouter.politykaPrywatnosci),
              ),
              _FooterLink(
                label: 'Umowa NDA',
                onTap: () => context.go(AppRouter.umowaNda),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileColumns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConfig.appName,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nieruchomości komercyjne i inwestycyjne – biura, magazyny, lokale handlowe, działki.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _FooterColumn(
          title: 'Nawigacja',
          links: [
            _FooterLink(label: 'Oferty', onTap: () => context.go(AppRouter.oferty)),
            _FooterLink(label: 'Kalkulator ROI', onTap: () => context.go(AppRouter.kalkulatorRoi)),
            _FooterLink(label: 'Chcę sprzedać', onTap: () => context.go(AppRouter.chceSprzedac)),
            _FooterLink(label: 'O nas', onTap: () => context.go(AppRouter.about)),
            _FooterLink(label: 'Kontakt', onTap: () => context.go(AppRouter.contact)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _FooterColumn(
          title: 'Kontakt',
          children: [
            _FooterContactRow(
              icon: Icons.email_outlined,
              label: AppConfig.contactEmail,
              onTap: () => _launchMailto(AppConfig.contactEmail),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FooterContactRow(
              icon: Icons.phone_outlined,
              label: AppConfig.supportPhone,
              onTap: () => _launchTel(AppConfig.supportPhone),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _FooterColumn(
          title: 'Prawne',
          links: [
            _FooterLink(
              label: 'Polityka prywatności',
              onTap: () => context.go(AppRouter.politykaPrywatnosci),
            ),
            _FooterLink(
              label: 'Umowa NDA',
              onTap: () => context.go(AppRouter.umowaNda),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchMailto(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchTel(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    this.links = const [],
    this.children,
  });

  final String title;
  final List<_FooterLink> links;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (links.isNotEmpty)
          ...links.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: link,
              )),
        if (children != null) ...children!,
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: _hovered ? AppColors.accent : AppColors.white.withValues(alpha: 0.85),
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _FooterContactRow extends StatelessWidget {
  const _FooterContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.white.withValues(alpha: 0.8)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
