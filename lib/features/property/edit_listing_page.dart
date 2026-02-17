import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/state/models/property_model.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/state/providers/dashboard_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../sell_submission/input_formatters.dart';

/// Strona edycji oferty – dostępna dla admina, agenta i właściciela oferty.
class EditListingPage extends ConsumerStatefulWidget {
  final String propertyId;

  const EditListingPage({super.key, required this.propertyId});

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _floorsController;
  late TextEditingController _locationController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _ownerEmailController;
  late TextEditingController _tenantController;
  late TextEditingController _roiController;

  bool _isSaving = false;
  Property? _property;
  bool _hasEditPermission = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _areaController = TextEditingController();
    _floorsController = TextEditingController();
    _locationController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _ownerNameController = TextEditingController();
    _ownerPhoneController = TextEditingController();
    _ownerEmailController = TextEditingController();
    _tenantController = TextEditingController();
    _roiController = TextEditingController();
  }

  void _populateFromProperty(Property p) {
    if (_property?.id == p.id) return;
    _property = p;
    _titleController.text = p.title;
    _descriptionController.text = p.description;
    _priceController.text = p.price.toStringAsFixed(0);
    _areaController.text = p.area.toStringAsFixed(0);
    _floorsController.text = p.floors.toString();
    _locationController.text = p.location;
    _cityController.text = p.city;
    _districtController.text = p.district ?? '';
    _ownerNameController.text = p.ownerName ?? '';
    _ownerPhoneController.text = p.ownerPhone ?? '';
    _ownerEmailController.text = p.ownerEmail ?? '';
    _tenantController.text = p.tenant ?? '';
    _roiController.text = p.roi != null ? p.roi!.toStringAsFixed(1) : '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _floorsController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _tenantController.dispose();
    _roiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = _property;
    if (p == null || !_hasEditPermission) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tytuł jest wymagany')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawną cenę')),
      );
      return;
    }

    final area = double.tryParse(_areaController.text.replaceAll(',', '.'));
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawną powierzchnię')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = Property(
      id: p.id,
      title: title,
      description: _descriptionController.text.trim(),
      price: price,
      pricePerSqm: area > 0 ? price / area : null,
      area: area,
      floors: int.tryParse(_floorsController.text) ?? p.floors,
      parkingSpaces: p.parkingSpaces,
      propertyType: p.propertyType,
      transactionType: p.transactionType,
      location: _locationController.text.trim().isEmpty
          ? _cityController.text.trim()
          : _locationController.text.trim(),
      city: _cityController.text.trim().isEmpty ? p.city : _cityController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      street: p.street,
      latitude: p.latitude,
      longitude: p.longitude,
      images: p.images,
      mainImage: p.mainImage,
      features: p.features,
      yearBuilt: p.yearBuilt,
      condition: p.condition,
      buildingClass: p.buildingClass,
      hasLoadingDock: p.hasLoadingDock,
      hasParking: p.hasParking,
      hasElevator: p.hasElevator,
      hasSecurity: p.hasSecurity,
      hasReception: p.hasReception,
      ceilingHeight: p.ceilingHeight,
      plotArea: p.plotArea,
      zoning: p.zoning,
      roi: double.tryParse(_roiController.text.replaceAll(',', '.')),
      currentRent: p.currentRent,
      tenant: _tenantController.text.trim().isEmpty ? null : _tenantController.text.trim(),
      leaseUntil: p.leaseUntil,
      verified: p.verified,
      promoted: p.promoted,
      ownerId: p.ownerId,
      ownerName: _ownerNameController.text.trim().isEmpty
          ? null
          : _ownerNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim().isEmpty
          ? null
          : _ownerPhoneController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim().isEmpty
          ? null
          : _ownerEmailController.text.trim(),
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      views: p.views,
      favorites: p.favorites,
      vdrDocuments: p.vdrDocuments,
    );

    final service = ref.read(listingsServiceProvider);
    final err = await service.updateListing(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu: $err'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oferta została zapisana'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/property/${p.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final propertyAsync = ref.watch(propertyDetailProvider(widget.propertyId));

    return propertyAsync.when(
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: const AppBarCustom(showBackButton: true),
            body: const Center(
              child: Text('Oferta nie została znaleziona'),
            ),
          );
        }

        _populateFromProperty(property);
        final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
        final canEdit = RolePermissions.canEditListing(
          roleLevel,
          user?.id,
          property.ownerId,
        );
        _hasEditPermission = canEdit;

        if (!canEdit) {
          return Scaffold(
            appBar: const AppBarCustom(showBackButton: true),
            body: const Center(
              child: Text('Brak uprawnień do edycji tej oferty'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBarCustom(
            showBackButton: true,
            title: 'Edytuj ofertę',
            onBackPressed: () => context.go('/property/${property.id}'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection('Podstawowe', [
                    _textField('Tytuł *', _titleController, maxLines: 2),
                    _textField('Opis', _descriptionController, maxLines: 6),
                  ]),
                  _buildSection('Cena i powierzchnia', [
                    _textField(
                      'Cena (PLN) *',
                      _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DecimalTextInputFormatter(maxLength: kMaxPriceLength),
                      ],
                    ),
                    _textField(
                      'Powierzchnia (m²) *',
                      _areaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DecimalTextInputFormatter(maxLength: kMaxAreaLength),
                      ],
                    ),
                    _textField(
                      'Liczba kondygnacji',
                      _floorsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    _textField(
                      'ROI (%)',
                      _roiController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ]),
                  _buildSection('Lokalizacja', [
                    _textField('Adres / Lokalizacja', _locationController),
                    _textField('Miasto', _cityController),
                    _textField('Dzielnica', _districtController),
                  ]),
                  _buildSection('Kontakt', [
                    _textField('Imię i nazwisko', _ownerNameController),
                    _textField(
                      'Telefon',
                      _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [phoneInputFormatter],
                    ),
                    _textField(
                      'Email',
                      _ownerEmailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ]),
                  if (property.propertyType != 'land')
                    _buildSection('Najemca (opcjonalnie)', [
                      _textField('Obecny najemca', _tenantController),
                    ]),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Zapisywanie…' : 'Zapisz zmiany'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: Center(child: Text('Błąd: $e')),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }
}
