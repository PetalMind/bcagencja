import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../listing_submission_model.dart';

/// Krok 3: Podstawowe dane – conditional (lokal z najemcą vs grunt).
class Step3BasicData extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;

  const Step3BasicData({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step3BasicData> createState() => _Step3BasicDataState();
}

class _Step3BasicDataState extends State<Step3BasicData> {
  late TextEditingController _areaController;
  late TextEditingController _tenantNameController;
  late TextEditingController _monthlyRentController;
  late TextEditingController _mpzpController;

  bool get _isLand => widget.formData.propertyType == 'land';
  bool get _isProperty =>
      widget.formData.propertyType != null &&
      widget.formData.propertyType != 'land' &&
      widget.formData.propertyType != 'unsure';

  static const List<String> _tenantOptions = [
    'long_term',
    'short_term',
    'vacant',
  ];
  static const List<String> _mpzpOptions = [
    'Zabudowa komercyjna/usługowa',
    'Zabudowa mieszkaniowa',
    'Teren przemysłowy',
    'Brak MPZP (WZ)',
    'Nie wiem / Trzeba sprawdzić',
  ];
  static const List<String> _utilityKeys = [
    'prąd',
    'woda',
    'kanalizacja',
    'gaz',
    'droga_dojazdowa',
  ];

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(
      text: widget.formData.area != null ? widget.formData.area!.toStringAsFixed(0) : '',
    );
    _tenantNameController = TextEditingController(text: widget.formData.tenantName ?? '');
    _monthlyRentController = TextEditingController(
      text: widget.formData.monthlyRent != null ? widget.formData.monthlyRent!.toStringAsFixed(0) : '',
    );
    _mpzpController = TextEditingController(text: widget.formData.mpzp ?? '');
  }

  @override
  void dispose() {
    _areaController.dispose();
    _tenantNameController.dispose();
    _monthlyRentController.dispose();
    _mpzpController.dispose();
    super.dispose();
  }

  void _syncArea() {
    final v = double.tryParse(_areaController.text.replaceAll(',', '.'));
    widget.formData.area = v != null && v > 0 ? v : null;
    widget.onDataChanged(widget.formData);
  }

  void _syncTenantAndRent() {
    widget.formData.tenantName = _tenantNameController.text.trim().isEmpty
        ? null
        : _tenantNameController.text.trim();
    final rent = double.tryParse(_monthlyRentController.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));
    widget.formData.monthlyRent = rent != null && rent > 0 ? rent : null;
    widget.onDataChanged(widget.formData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Powiedz nam więcej',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLand) ..._buildLandFields() else if (_isProperty) ..._buildPropertyFields() else ..._buildGenericFields(),
        ],
      ),
    );
  }

  List<Widget> _buildPropertyFields() {
    final showTenantDetails =
        widget.formData.tenantType == 'long_term';

    return [
      Text(
        'Powierzchnia (GLA):',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _areaController,
        onChanged: (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Powierzchnia (m²)',
          suffixText: 'm²',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Czy nieruchomość ma najemcę?',
        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
      ),
      const SizedBox(height: AppSpacing.sm),
      ..._tenantOptions.map((value) => _radioOption(value)),
      if (showTenantDetails) ...[
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _tenantNameController,
          onChanged: (_) => _syncTenantAndRent(),
          decoration: InputDecoration(
            labelText: 'Kim jest najemca?',
            hintText: 'np. Biedronka, Lidl, Żabka',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildDateField(),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _monthlyRentController,
          onChanged: (_) => _syncTenantAndRent(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Miesięczny czynsz (netto)',
            suffixText: 'PLN',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.white,
          ),
        ),
        if (widget.formData.estimatedValueFromRent != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Szacunkowa wartość: ~${_formatPrice(widget.formData.estimatedValueFromRent!)} PLN',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    ];
  }

  Widget _radioOption(String value) {
    final labels = {
      'long_term': 'Tak, z długoterminową umową (najlepsze!)',
      'short_term': 'Tak, z krótką umową',
      'vacant': 'Nie, pustostan',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RadioListTile<String>(
        value: value,
        groupValue: widget.formData.tenantType,
        title: Text(labels[value] ?? value, style: AppTextStyles.bodyMedium),
        onChanged: (v) {
          widget.formData.tenantType = v;
          widget.onDataChanged(widget.formData);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildDateField() {
    final d = widget.formData.leaseUntil;
    final text = d != null ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}' : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Do kiedy trwa umowa?', style: AppTextStyles.labelLarge),
      subtitle: Text(text.isEmpty ? 'Wybierz datę' : text, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.calendar_today_rounded),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: d ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
        );
        if (picked != null) {
          widget.formData.leaseUntil = picked;
          widget.onDataChanged(widget.formData);
          setState(() {});
        }
      },
    );
  }

  List<Widget> _buildLandFields() {
    return [
      Text(
        'Powierzchnia działki:',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _areaController,
        onChanged: (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Powierzchnia (m²)',
          hintText: 'np. 5000',
          suffixText: 'm² = $_areaHa ha',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Przeznaczenie w MPZP:',
        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
      ),
      const SizedBox(height: AppSpacing.sm),
      ..._mpzpOptions.map((label) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: RadioListTile<String>(
              value: label,
              groupValue: widget.formData.mpzp,
              title: Text(label, style: AppTextStyles.bodyMedium),
              onChanged: (v) {
                widget.formData.mpzp = v;
                widget.onDataChanged(widget.formData);
                setState(() {});
              },
            ),
          )),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Uzbrojenie:',
        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryDark),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _utilityKeys.map((key) {
          final label = key == 'droga_dojazdowa' ? 'Droga dojazdowa' : key[0].toUpperCase() + key.substring(1);
          final selected = widget.formData.utilities.contains(key);
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (isSelected) {
              if (isSelected) {
                widget.formData.utilities = [...widget.formData.utilities, key];
              } else {
                widget.formData.utilities = widget.formData.utilities.where((e) => e != key).toList();
              }
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
          );
        }).toList(),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.ctaHighlight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Im więcej uzbrojenia, tym wyższa wartość',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildGenericFields() {
    return [
      Text(
        'Powierzchnia (m²):',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _areaController,
        onChanged: (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Powierzchnia',
          suffixText: 'm²',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    ];
  }

  String get _areaHa {
    final a = widget.formData.area;
    if (a == null || a <= 0) return '—';
    return (a / 10000).toStringAsFixed(2);
  }

  static String _formatPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} tys.';
    return v.toStringAsFixed(0);
  }
}
