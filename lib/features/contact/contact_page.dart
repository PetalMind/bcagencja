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
import '../../widgets/common/custom_button.dart';

/// Makieta strony kontaktowej – dane kontaktowe i formularz.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
            _ContactHero(isMobile: isMobile),
            _ContactInfo(isMobile: isMobile),
            _ContactFormSection(context, isMobile),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _ContactFormSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      color: AppColors.grey50,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: AppSpacing.containerMaxWidthNarrow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Napisz do nas',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Opisz krótko, czego szukasz lub zadaj pytanie – odezwiemy się w ciągu 24 h.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ContactForm(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactHero extends StatelessWidget {
  final bool isMobile;

  const _ContactHero({required this.isMobile});

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
                'Kontakt',
                style: (isMobile
                        ? AppTextStyles.headlineLarge
                        : AppTextStyles.displaySmall)
                    .copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Masz pytania? Chętnie pomożemy w znalezieniu oferty lub odpowiedzi.',
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

class _ContactInfo extends StatelessWidget {
  final bool isMobile;

  const _ContactInfo({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': AppIcons.phone,
        'title': 'Telefon',
        'value': '+48 22 123 45 67',
        'sub': 'Pn–Pt 9:00–18:00',
      },
      {
        'icon': AppIcons.email,
        'title': 'E-mail',
        'value': 'biuro@bcagencja.pl',
        'sub': 'Odpowiadamy w ciągu 24 h',
      },
      {
        'icon': AppIcons.location,
        'title': 'Adres',
        'value': 'ul. Przykładowa 1',
        'sub': '00-001 Warszawa',
      },
    ];

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
            children: [
              Text(
                'Dane kontaktowe',
                style: (isMobile
                        ? AppTextStyles.headlineMedium
                        : AppTextStyles.headlineLarge)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              isMobile
                  ? Column(
                      children: items
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              child: _ContactInfoCard(
                                icon: e['icon'] as IconData,
                                title: e['title'] as String,
                                value: e['value'] as String,
                                sub: e['sub'] as String,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map(
                            (e) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: _ContactInfoCard(
                                  icon: e['icon'] as IconData,
                                  title: e['title'] as String,
                                  value: e['value'] as String,
                                  sub: e['sub'] as String,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String sub;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.sub,
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
        children: [
          Icon(icon, color: AppColors.accent, size: AppSpacing.iconLg),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sub,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  final bool isMobile;

  const _ContactForm({required this.isMobile});

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Imię i nazwisko',
                hintText: 'Jan Kowalski',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AppIcons.profile, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'jan@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AppIcons.email, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Temat',
                hintText: 'np. Zapytanie o ofertę magazynową',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AppIcons.message, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Wiadomość',
                hintText: 'Opisz krótko, czego szukasz...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              label: 'Wyślij wiadomość',
              onPressed: () {
                // Makieta – bez wysyłki
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formularz to makieta – wysyłka nie jest zaimplementowana.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              variant: ButtonVariant.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
