import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step6Summary extends StatelessWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;

  const Step6Summary({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  static String _transactionLabel(String? v) {
    if (v == null) return '—';
    return v == 'sale' ? 'Sprzedaż' : 'Wynajem';
  }

  static String _propertyTypeLabel(String? v) {
    const map = {
      'office': 'Biurowiec',
      'warehouse': 'Magazyn',
      'retail': 'Handlowy',
      'industrial': 'Przemysłowy',
      'hotel': 'Hotel',
      'land': 'Działka',
    };
    return v == null ? '—' : (map[v] ?? v);
  }

  static String _amenityLabel(String v) {
    const map = {
      'parking': 'Parking',
      'elevator': 'Windy',
      'airConditioning': 'Klimatyzacja',
      'monitoring': 'Monitoring',
      'reception': 'Recepcja',
      'access24': 'Dostęp 24h',
    };
    return map[v] ?? v;
  }

  static String _formatPrice(double? v) {
    if (v == null) return '—';
    final s = v.toStringAsFixed(0);
    if (s.length <= 3) return '$s PLN';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} PLN';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Podsumowanie ogłoszenia', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Typ i lokalizacja',
            children: [
              _Row('Typ transakcji', _transactionLabel(formData.transactionType)),
              _Row('Typ nieruchomości', _propertyTypeLabel(formData.propertyType)),
              _Row('Miasto', formData.city ?? '—'),
              if (formData.district != null && formData.district!.isNotEmpty)
                _Row('Dzielnica / Osiedle', formData.district!),
              if (formData.street != null && formData.street!.isNotEmpty)
                _Row('Ulica', formData.street!),
            ],
          ),
          _Section(
            title: 'Podstawy',
            children: [
              _Row('Cena', _formatPrice(formData.price)),
              _Row('Powierzchnia', formData.area != null ? '${formData.area} m²' : '—'),
              _Row('Liczba pokoi', formData.rooms?.toString() ?? '—'),
              if (formData.floor != null) _Row('Piętro', formData.floor.toString()),
              if (formData.yearBuilt != null) _Row('Rok budowy', formData.yearBuilt.toString()),
              if (formData.condition != null) _Row('Stan', formData.condition!),
            ],
          ),
          _Section(
            title: 'Szczegóły',
            children: [
              _Row(
                'Opis',
                formData.description != null && formData.description!.isNotEmpty
                    ? (formData.description!.length > 100
                        ? '${formData.description!.substring(0, 100)}...'
                        : formData.description!)
                    : '—',
              ),
              if (formData.amenities.isNotEmpty)
                _Row(
                  'Udogodnienia',
                  formData.amenities
                      .map((v) => _amenityLabel(v))
                      .join(', '),
                ),
              if (formData.heating != null) _Row('Ogrzewanie', formData.heating!),
            ],
          ),
          _Section(
            title: 'Zdjęcia',
            children: [
              _Row('Liczba zdjęć', '${formData.images.length}'),
            ],
          ),
          _Section(
            title: 'Kontakt',
            children: [
              _Row('Imię i nazwisko', formData.contactName ?? '—'),
              _Row('Telefon', formData.contactPhone ?? '—'),
              _Row('E-mail', formData.contactEmail ?? '—'),
              if (formData.preferredContactTime != null)
                _Row('Preferowany czas', formData.preferredContactTime!),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Pakiet publikacji', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PackageCard(
                  title: 'Basic',
                  description: 'Standardowa widoczność',
                  value: 'basic',
                  isSelected: formData.package == 'basic',
                  onTap: () {
                    formData.package = 'basic';
                    onDataChanged(formData);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PackageCard(
                  title: 'Promowany',
                  description: 'Wyróżniona oferta',
                  value: 'promoted',
                  isSelected: formData.package == 'promoted',
                  onTap: () {
                    formData.package = 'promoted';
                    onDataChanged(formData);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          StatefulBuilder(
            builder: (context, setState) {
              return CheckboxListTile(
                value: formData.acceptedTerms,
                onChanged: (v) {
                  formData.acceptedTerms = v ?? false;
                  onDataChanged(formData);
                  setState(() {});
                },
                title: Text(
                  'Akceptuję regulamin i politykę prywatności serwisu *',
                  style: AppTextStyles.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.title,
    required this.description,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
