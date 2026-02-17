import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 5: Dokumentacja – opcjonalnie, przycisk "Pomiń ten krok".
class Step5Documentation extends StatelessWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;

  const Step5Documentation({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masz już dokumentację?',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Możesz załączyć dokumenty (opcjonalnie – możesz wysłać je później):',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file_rounded, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Przeciągnij pliki tutaj lub kliknij',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Przyjmujemy: PDF, JPG, PNG (max 10MB/plik)',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Przydatne dokumenty:',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _bullet('Wypis z KW'),
          _bullet('Umowa najmu (jeśli dotyczy)'),
          _bullet('MPZP / Warunki zabudowy'),
          _bullet('Zdjęcia nieruchomości'),
          _bullet('Operat szacunkowy (jeśli posiadasz)'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Załączone (${formData.attachmentNames.length}):',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (formData.attachmentNames.isEmpty)
            Text(
              'Brak plików',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              children: formData.attachmentNames
                  .map((name) => Chip(label: Text(name), onDeleted: () {}))
                  .toList(),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nie chcemy stracić leada z powodu braku dokumentów – możesz uzupełnić później w kontakcie z agentem.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
