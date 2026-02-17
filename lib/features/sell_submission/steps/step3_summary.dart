import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 3: Podsumowanie zgłoszenia przed wysłaniem.
class Step3Summary extends StatelessWidget {
  final ListingSubmissionData formData;

  const Step3Summary({
    super.key,
    required this.formData,
  });

  static String _assetTypeLabel(String? type) {
    switch (type) {
      case 'property':
        return 'Nieruchomość';
      case 'land':
        return 'Grunt';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sprawdź dane i wyślij zgłoszenie',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Po wysłaniu skontaktujemy się w ciągu 1–2 dni roboczych.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SummaryCard(
            title: 'Co sprzedajesz',
            children: [
              _SummaryRow('Typ', _assetTypeLabel(formData.assetType)),
              _SummaryRow('Miasto', formData.city ?? '—'),
              if (formData.voivodeship != null &&
                  formData.voivodeship!.trim().isNotEmpty)
                _SummaryRow('Województwo', formData.voivodeship!),
              if (formData.description != null &&
                  formData.description!.trim().isNotEmpty)
                _SummaryRow('Opis', formData.description!),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryCard(
            title: 'Kontakt',
            children: [
              _SummaryRow('Imię i nazwisko', formData.contactName ?? '—'),
              _SummaryRow('E-mail', formData.contactEmail ?? '—'),
              _SummaryRow('Telefon', formData.contactPhone ?? '—'),
              if (formData.preferredContactTime != null &&
                  formData.preferredContactTime!.trim().isNotEmpty)
                _SummaryRow(
                    'Preferowana godzina', formData.preferredContactTime!),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SummaryCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
