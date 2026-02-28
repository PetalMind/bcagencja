import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/google_places_service.dart';
import '../input_formatters.dart';
import '../listing_submission_model.dart';

/// Krok 2: Lokalizacja – sekcje (Szybki sposób / Szczegóły / Prywatność), naturalna kolejność pól, checkbox hideExactAddress.
class Step2Location extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  final VoidCallback? onAddressSelected;
  final bool readOnly;

  const Step2Location({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.onAddressSelected,
    this.readOnly = false,
  });

  @override
  State<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends State<Step2Location> {
  late TextEditingController _streetController;
  late TextEditingController _buildingNumberController;
  late TextEditingController _apartmentNumberController;
  late TextEditingController _postalCodeController;
  late TextEditingController _localityController;
  late TextEditingController _autocompleteController;
  bool _isResolvingLocation = false;
  bool _isLoadingDetails = false;
  List<PlacePrediction> _predictions = [];
  bool _showOverlay = false;
  Timer? _debounceTimer;
  final _placesService = GooglePlacesService();
  final LayerLink _layerLink = LayerLink();

  static const List<String> _voivodeships = [
    'dolnośląskie', 'kujawsko-pomorskie', 'lubelskie', 'lubuskie',
    'łódzkie', 'małopolskie', 'mazowieckie', 'opolskie',
    'podkarpackie', 'podlaskie', 'pomorskie', 'śląskie',
    'świętokrzyskie', 'warmińsko-mazurskie', 'wielkopolskie', 'zachodniopomorskie',
  ];

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController(text: widget.formData.street ?? '');
    _buildingNumberController = TextEditingController(text: widget.formData.buildingNumber ?? '');
    _apartmentNumberController = TextEditingController(text: widget.formData.apartmentNumber ?? '');
    _postalCodeController = TextEditingController(text: widget.formData.postalCode ?? '');
    _localityController = TextEditingController(text: widget.formData.locality ?? '');
    _autocompleteController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _apartmentNumberController.dispose();
    _postalCodeController.dispose();
    _localityController.dispose();
    _autocompleteController.dispose();
    super.dispose();
  }

  void _syncToFormData() {
    widget.formData.street = _streetController.text.trim().isEmpty ? null : _streetController.text.trim();
    widget.formData.buildingNumber = _buildingNumberController.text.trim().isEmpty ? null : _buildingNumberController.text.trim();
    widget.formData.apartmentNumber = _apartmentNumberController.text.trim().isEmpty ? null : _apartmentNumberController.text.trim();
    widget.formData.postalCode = _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim();
    widget.formData.locality = _localityController.text.trim().isEmpty ? null : _localityController.text.trim().toUpperCase();
    widget.onDataChanged(widget.formData);
  }

  void _onAutocompleteTextChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _predictions = [];
        _showOverlay = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () => _fetchPredictions(value.trim()));
  }

  Future<void> _fetchPredictions(String input) async {
    final list = await _placesService.autocomplete(input);
    if (!mounted) return;
    setState(() {
      _predictions = list;
      _showOverlay = list.isNotEmpty;
    });
  }

  void _hideOverlay() {
    setState(() {
      _showOverlay = false;
      _predictions = [];
    });
  }

  /// Uzupełnia pola adresowe z PlaceDetails. Miejscowość w WIELKICH LITERACH.
  void _applyPlaceDetails(PlaceDetails details) {
    final streetName = details.street?.trim() ?? '';
    final street = streetName.isNotEmpty ? (streetName.toLowerCase().startsWith('ul.') ? streetName : 'ul. $streetName') : null;
    widget.formData.street = street;
    widget.formData.buildingNumber = details.streetNumber?.trim().isEmpty == true ? null : details.streetNumber?.trim();
    widget.formData.postalCode = details.postalCode?.trim().isEmpty == true ? null : details.postalCode?.trim();
    widget.formData.locality = details.locality?.trim().isEmpty == true ? null : details.locality!.trim().toUpperCase();
    widget.formData.formattedAddress = details.formattedAddress;
    widget.formData.voivodeship = _normalizeVoivodeship(details.administrativeArea);
    widget.formData.latitude = details.latitude;
    widget.formData.longitude = details.longitude;
    _streetController.text = widget.formData.street ?? '';
    _buildingNumberController.text = widget.formData.buildingNumber ?? '';
    _postalCodeController.text = widget.formData.postalCode ?? '';
    _localityController.text = widget.formData.locality ?? '';
    _syncToFormData();
  }

  Future<void> _onSelectPlace(PlacePrediction prediction) async {
    _hideOverlay();
    setState(() => _isLoadingDetails = true);
    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (!mounted) return;
    setState(() => _isLoadingDetails = false);
    if (details == null) return;
    _applyPlaceDetails(details);
    setState(() {});
    widget.onAddressSelected?.call();
  }

  String? _normalizeVoivodeship(String? area) {
    if (area == null || area.isEmpty) return null;
    final lower = area.toLowerCase();
    for (final v in _voivodeships) {
      if (lower == v || lower.contains(v) || v.contains(lower)) return v;
    }
    return lower;
  }

  Future<void> _useMyLocation() async {
    setState(() => _isResolvingLocation = true);
    String? errorMessage;
    try {
      if (!kIsWeb) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          errorMessage = 'Włącz usługi lokalizacji w ustawieniach urządzenia.';
          if (mounted) {
            final open = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Lokalizacja wyłączona'),
                content: const Text(
                  'Aby użyć „Użyj mojej lokalizacji”, włącz GPS lub lokalizację w ustawieniach.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Otwórz ustawienia')),
                ],
              ),
            );
            if (open == true) await Geolocator.openLocationSettings();
          }
          return;
        }
      }

      // Na web pomijamy checkPermission/requestPermission – przeglądarka pokazuje
      // własny dialog przy getCurrentPosition(). Flow permission na web bywa zawodny.
      if (!kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          errorMessage = 'Brak dostępu do lokalizacji. Wpisz adres ręcznie lub zezwól w ustawieniach.';
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        ),
      );

      final details = await _placesService.reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;
      if (details == null) {
        widget.formData.latitude = position.latitude;
        widget.formData.longitude = position.longitude;
        widget.formData.locality = 'LOKALIZACJA';
        _localityController.text = 'LOKALIZACJA';
        _syncToFormData();
        widget.onAddressSelected?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokalizacja zapisana. Uzupełnij adres i województwo.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      _applyPlaceDetails(details);
      if (mounted) setState(() {});
      widget.onAddressSelected?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokalizacja ustawiona – sprawdź pola i przejdź dalej.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on TimeoutException catch (_) {
      errorMessage = 'Upłynął limit czasu. Sprawdź połączenie i spróbuj ponownie.';
    } catch (e) {
      errorMessage = 'Nie udało się pobrać lokalizacji. Wpisz adres ręcznie.';
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gdzie się znajduje?',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Dokładny adres potrzebny jest tylko do weryfikacji i dopasowania oferty do regionu. Na portalu pokazujemy tylko rejon.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              // --- Sekcja: Szybki sposób ---
              Card(
                elevation: 0,
                color: AppColors.grey50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Szybki sposób',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: widget.readOnly || _isResolvingLocation ? null : _useMyLocation,
                        icon: _isResolvingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: const Text('Użyj mojej lokalizacji'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'lub wyszukaj adres:',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: TextFormField(
                          controller: _autocompleteController,
                          readOnly: widget.readOnly,
                          onChanged: widget.readOnly ? null : _onAutocompleteTextChanged,
                          onTap: widget.readOnly ? null : () {
                            if (_predictions.isNotEmpty) setState(() => _showOverlay = true);
                          },
                          decoration: InputDecoration(
                            hintText: 'np. Poznań, ul. Półwiejska 1',
                            prefixIcon: _isLoadingDetails
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // --- Sekcja: Szczegóły adresu (naturalna kolejność) ---
              Card(
                elevation: 0,
                color: AppColors.grey50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Szczegóły adresu (do weryfikacji)',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                      ),
                      Text(
                        'Zweryfikuj lub uzupełnij pola oznaczone gwiazdką (*)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Miejscowość (na początku – naturalny flow)
                      TextFormField(
                        controller: _localityController,
                        readOnly: widget.readOnly,
                        onChanged: (_) => _syncToFormData(),
                        maxLength: kMaxLocalityLength,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          labelText: 'Miejscowość *',
                          hintText: 'WIELKIMI LITERAMI (standard Poczty Polskiej)',
                          counterText: '',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _postalCodeController,
                        readOnly: widget.readOnly,
                        onChanged: (_) => _syncToFormData(),
                        maxLength: kPostalCodeLength,
                        inputFormatters: [postalCodeInputFormatter, LengthLimitingTextInputFormatter(kPostalCodeLength)],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kod pocztowy *',
                          hintText: 'XX-XXX',
                          counterText: '',
                          prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _streetController,
                        readOnly: widget.readOnly,
                        onChanged: (_) => _syncToFormData(),
                        maxLength: kMaxStreetLength,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ulica *',
                          hintText: 'np. ul. Piotrkowska',
                          counterText: '',
                          prefixIcon: Icon(Icons.signpost_outlined),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _buildingNumberController,
                              readOnly: widget.readOnly,
                              onChanged: (_) => _syncToFormData(),
                              maxLength: kMaxBuildingNumberLength,
                              decoration: const InputDecoration(
                                labelText: 'Numer domu *',
                                hintText: 'np. 15',
                                counterText: '',
                                prefixIcon: Icon(Icons.numbers),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _apartmentNumberController,
                              readOnly: widget.readOnly,
                              onChanged: (_) => _syncToFormData(),
                              maxLength: kMaxApartmentNumberLength,
                              decoration: const InputDecoration(
                                labelText: 'Nr lokalu',
                                hintText: 'opcjonalnie',
                                counterText: '',
                                prefixIcon: Icon(Icons.apartment),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        key: ValueKey(widget.formData.voivodeship ?? ''),
                        initialValue: widget.formData.voivodeship != null &&
                                _voivodeships.contains(widget.formData.voivodeship!.toLowerCase())
                            ? widget.formData.voivodeship!.toLowerCase()
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Województwo',
                          prefixIcon: Icon(Icons.map_outlined),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Wybierz z listy')),
                          ..._voivodeships.map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v[0].toUpperCase() + v.substring(1)),
                            ),
                          ),
                        ],
                        onChanged: widget.readOnly ? null : (v) {
                          widget.formData.voivodeship = v;
                          widget.onDataChanged(widget.formData);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // --- Sekcja: Prywatność ---
              Card(
                elevation: 0,
                color: AppColors.grey50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: CheckboxListTile(
                    value: widget.formData.hideExactAddress,
                    onChanged: widget.readOnly
                        ? null
                        : (v) {
                            widget.formData.hideExactAddress = v ?? true;
                            widget.onDataChanged(widget.formData);
                            setState(() {});
                          },
                    title: Text(
                      'Nie publikuj dokładnego adresu – pokazuj tylko rejon',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                    ),
                    subtitle: Text(
                      'Kluczowe dla off-market – adres służy tylko do weryfikacji i dopasowania do regionu.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.readOnly && _showOverlay && _predictions.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.opaque,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, 48),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - AppSpacing.lg * 2,
                        maxHeight: 280,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final p = _predictions[index];
                          return ListTile(
                            leading: Icon(Icons.place_outlined, color: AppColors.accent, size: 22),
                            title: Text(
                              p.mainText,
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                            ),
                            subtitle: p.secondaryText.isNotEmpty
                                ? Text(
                                    p.secondaryText,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _onSelectPlace(p),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
