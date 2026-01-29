import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step2Basics extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;

  const Step2Basics({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step2Basics> createState() => _Step2BasicsState();
}

class _Step2BasicsState extends State<Step2Basics> {
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _roomsController;
  late TextEditingController _floorController;
  late TextEditingController _yearBuiltController;

  static const _conditionOptions = [
    'Do remontu',
    'Do wynajęcia',
    'Dobry',
    'Bardzo dobry',
    'Nowy',
  ];

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.formData.price != null ? widget.formData.price!.toString() : '',
    );
    _areaController = TextEditingController(
      text: widget.formData.area != null ? widget.formData.area!.toString() : '',
    );
    _roomsController = TextEditingController(
      text: widget.formData.rooms != null ? widget.formData.rooms!.toString() : '',
    );
    _floorController = TextEditingController(
      text: widget.formData.floor != null ? widget.formData.floor!.toString() : '',
    );
    _yearBuiltController = TextEditingController(
      text: widget.formData.yearBuilt != null ? widget.formData.yearBuilt!.toString() : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _floorController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.price = _parseDouble(_priceController.text);
    widget.formData.area = _parseDouble(_areaController.text);
    widget.formData.rooms = _parseInt(_roomsController.text);
    widget.formData.floor = _parseInt(_floorController.text);
    widget.formData.yearBuilt = _parseInt(_yearBuiltController.text);
    widget.onDataChanged(widget.formData);
  }

  double? _parseDouble(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  int? _parseInt(String s) {
    if (s.trim().isEmpty) return null;
    return int.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Podstawowe informacje', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pola wymagane: Cena, Powierzchnia, Liczba pokoi',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Cena (PLN) *',
              prefixIcon: Icon(AppIcons.price),
              hintText: 'np. 1500000',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s,]'))],
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'Powierzchnia (m²) *',
              prefixIcon: Icon(AppIcons.area),
              hintText: 'np. 250',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _roomsController,
            decoration: const InputDecoration(
              labelText: 'Liczba pokoi *',
              prefixIcon: Icon(AppIcons.rooms),
              hintText: 'np. 5',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Dodatkowe (opcjonalnie)', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _floorController,
            decoration: const InputDecoration(
              labelText: 'Piętro',
              prefixIcon: Icon(AppIcons.floors),
              hintText: 'np. 2',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _yearBuiltController,
            decoration: const InputDecoration(
              labelText: 'Rok budowy',
              prefixIcon: Icon(Icons.calendar_today_rounded),
              hintText: 'np. 2010',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (_) => _syncToFormData(),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: widget.formData.condition,
            decoration: const InputDecoration(
              labelText: 'Stan nieruchomości (opcjonalnie)',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nie wybrano')),
              ..._conditionOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))),
            ],
            onChanged: (v) {
              widget.formData.condition = v;
              widget.onDataChanged(widget.formData);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
