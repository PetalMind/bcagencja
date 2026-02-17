import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../input_formatters.dart';
import '../listing_submission_model.dart';

/// Krok 3: Podstawowe dane – conditional (lokal z najemcą vs grunt).
class Step3BasicData extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final bool readOnly;

  const Step3BasicData({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.readOnly = false,
  });

  @override
  State<Step3BasicData> createState() => _Step3BasicDataState();
}

class _Step3BasicDataState extends State<Step3BasicData> {
  late TextEditingController _areaController;
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
    _mpzpController = TextEditingController(text: widget.formData.mpzp ?? '');
    // Gdy long_term i brak najemców (np. powrót do kroku) – dodaj jednego
    if (widget.formData.tenantType == 'long_term' && widget.formData.tenants.isEmpty) {
      widget.formData.tenants.add(TenantEntry());
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _mpzpController.dispose();
    super.dispose();
  }

  void _syncArea() {
    final v = double.tryParse(_areaController.text.replaceAll(',', '.'));
    widget.formData.area = v != null && v > 0 ? v : null;
    widget.onDataChanged(widget.formData);
  }

  void _addTenant() {
    widget.formData.tenants.add(TenantEntry());
    widget.onDataChanged(widget.formData);
    setState(() {});
  }

  void _updateTenant(int index, TenantEntry t) {
    if (index >= 0 && index < widget.formData.tenants.length) {
      widget.formData.tenants[index] = t;
      widget.onDataChanged(widget.formData);
      setState(() {});
    }
  }

  void _removeTenant(int index) {
    if (index >= 0 && index < widget.formData.tenants.length) {
      widget.formData.tenants.removeAt(index);
      widget.onDataChanged(widget.formData);
      setState(() {});
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
        readOnly: widget.readOnly,
        onChanged: widget.readOnly ? null : (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          DecimalTextInputFormatter(maxLength: kMaxAreaLength),
          LengthLimitingTextInputFormatter(kMaxAreaLength),
        ],
        decoration: InputDecoration(
          labelText: 'Powierzchnia (m²)',
          suffixText: 'm²',
          helperText: 'Tylko cyfry',
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
        Text(
          'Najemcy (lokalizacja może mieć wielu najemców)',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(
          widget.formData.tenants.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _TenantCard(
              key: ValueKey('tenant_$i'),
              tenant: widget.formData.tenants[i],
              index: i,
              canRemove: widget.formData.tenants.length > 1 && !widget.readOnly,
              onChanged: (t) => _updateTenant(i, t),
              onRemove: () => _removeTenant(i),
              readOnly: widget.readOnly,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.readOnly ? null : _addTenant,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Dodaj najemcę'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.formData.estimatedValueFromRent != null) ...[
          Text(
            'Szacunkowa wartość (suma czynszów): ~${_formatPrice(widget.formData.estimatedValueFromRent!)} PLN',
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
        onChanged: widget.readOnly ? null : (v) {
          widget.formData.tenantType = v;
          if (v == 'long_term' && widget.formData.tenants.isEmpty) {
            widget.formData.tenants.add(TenantEntry());
          }
          widget.onDataChanged(widget.formData);
          setState(() {});
        },
      ),
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
        readOnly: widget.readOnly,
        onChanged: widget.readOnly ? null : (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          DecimalTextInputFormatter(maxLength: kMaxAreaLength),
          LengthLimitingTextInputFormatter(kMaxAreaLength),
        ],
        decoration: InputDecoration(
          labelText: 'Powierzchnia (m²)',
          hintText: 'np. 5000',
          suffixText: 'm² = $_areaHa ha',
          helperText: 'Tylko cyfry',
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
              onChanged: widget.readOnly ? null : (v) {
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
            onSelected: widget.readOnly ? null : (isSelected) {
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
        readOnly: widget.readOnly,
        onChanged: widget.readOnly ? null : (_) => _syncArea(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          DecimalTextInputFormatter(maxLength: kMaxAreaLength),
          LengthLimitingTextInputFormatter(kMaxAreaLength),
        ],
        decoration: InputDecoration(
          labelText: 'Powierzchnia',
          suffixText: 'm²',
          helperText: 'Tylko cyfry',
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

/// Karta pojedynczego najemcy (nazwa, termin umowy, czynsz).
class _TenantCard extends StatefulWidget {
  final TenantEntry tenant;
  final int index;
  final bool canRemove;
  final ValueChanged<TenantEntry> onChanged;
  final VoidCallback onRemove;
  final bool readOnly;

  const _TenantCard({
    super.key,
    required this.tenant,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    this.readOnly = false,
  });

  @override
  State<_TenantCard> createState() => _TenantCardState();
}

class _TenantCardState extends State<_TenantCard> {
  late TextEditingController _nameController;
  late TextEditingController _rentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tenant.name);
    _rentController = TextEditingController(
      text: widget.tenant.monthlyRent != null ? widget.tenant.monthlyRent!.toStringAsFixed(0) : '',
    );
  }

  @override
  void didUpdateWidget(_TenantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenant != widget.tenant) {
      // Aktualizuj tylko gdy zmiana przyszła z zewnątrz (np. ładowanie),
      // nie gdy my wywołaliśmy onChanged – inaczej każde naciśnięcie klawisza
      // nadpisywałoby kontroler i zaznaczało cały tekst.
      if (_nameController.text != widget.tenant.name) {
        _nameController.text = widget.tenant.name;
      }
      final newRentText = widget.tenant.monthlyRent != null
          ? widget.tenant.monthlyRent!.toStringAsFixed(0)
          : '';
      if (_rentController.text != newRentText) {
        _rentController.text = newRentText;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  void _sync() {
    final t = TenantEntry(
      name: _nameController.text.trim(),
      leaseUntil: widget.tenant.leaseUntil,
      monthlyRent: double.tryParse(
        _rentController.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'),
      ),
    );
    if (t.monthlyRent != null && t.monthlyRent! <= 0) t.monthlyRent = null;
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Najemca ${widget.index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (widget.canRemove && !widget.readOnly)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onRemove,
                    tooltip: 'Usuń najemcę',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              readOnly: widget.readOnly,
              onChanged: widget.readOnly ? null : (_) => _sync(),
              maxLength: kMaxNameLength,
              decoration: InputDecoration(
                labelText: 'Kim jest najemca?',
                hintText: 'np. Biedronka, Lidl, Żabka',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.white,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDateField(),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _rentController,
              readOnly: widget.readOnly,
              onChanged: widget.readOnly ? null : (_) => _sync(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                DecimalTextInputFormatter(maxLength: kMaxRentLength),
                LengthLimitingTextInputFormatter(kMaxRentLength),
              ],
              decoration: InputDecoration(
                labelText: 'Miesięczny czynsz (netto)',
                suffixText: 'PLN',
                helperText: 'Tylko cyfry',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final d = widget.tenant.leaseUntil;
    final text = d != null
        ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
        : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Do kiedy trwa umowa?', style: AppTextStyles.labelLarge),
      subtitle: Text(text.isEmpty ? 'Wybierz datę' : text, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.calendar_today_rounded),
      onTap: widget.readOnly ? null : () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: d ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
        );
        if (picked != null) {
          final t = TenantEntry(
            name: _nameController.text.trim(),
            leaseUntil: picked,
            monthlyRent: widget.tenant.monthlyRent,
          );
          widget.onChanged(t);
        }
      },
    );
  }
}
