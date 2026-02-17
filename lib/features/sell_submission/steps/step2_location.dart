import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/google_places_service.dart';
import '../listing_submission_model.dart';

/// Krok 2: Lokalizacja – Google Places autocomplete (dokładny adres) + "Użyj mojej lokalizacji" + ręczne miasto/województwo.
/// Po wyborze adresu z listy widok sam przechodzi do kroku 3.
class Step2Location extends StatefulWidget {
  final ListingSubmissionData formData;
  final ValueChanged<ListingSubmissionData> onDataChanged;
  /// Wywołane po wyborze dokładnego adresu z Google – rodzic może przejść do następnego kroku.
  final VoidCallback? onAddressSelected;

  const Step2Location({
    super.key,
    required this.formData,
    required this.onDataChanged,
    this.onAddressSelected,
  });

  @override
  State<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends State<Step2Location> {
  late TextEditingController _addressController;
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
    _addressController = TextEditingController(text: widget.formData.formattedAddress ?? widget.formData.city ?? '');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  void _syncToFormDataFromFields() {
    final t = _addressController.text.trim();
    if (t.isNotEmpty && widget.formData.formattedAddress == null) {
      widget.formData.city = t;
    }
    widget.onDataChanged(widget.formData);
  }

  void _onAddressTextChanged(String value) {
    _syncToFormDataFromFields();
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

  Future<void> _onSelectPlace(PlacePrediction prediction) async {
    _hideOverlay();
    setState(() => _isLoadingDetails = true);
    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (!mounted) return;
    setState(() => _isLoadingDetails = false);
    if (details == null) return;

    widget.formData.formattedAddress = details.formattedAddress;
    final parts = details.formattedAddress.split(',');
    widget.formData.city = details.locality?.trim().isNotEmpty == true
        ? details.locality
        : (parts.isNotEmpty ? parts.first.trim() : details.formattedAddress);
    widget.formData.voivodeship = _normalizeVoivodeship(details.administrativeArea);
    widget.formData.latitude = details.latitude;
    widget.formData.longitude = details.longitude;
    _addressController.text = details.formattedAddress;
    widget.onDataChanged(widget.formData);
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

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        errorMessage = 'Brak dostępu do lokalizacji. Wpisz adres ręcznie lub zezwól w ustawieniach.';
        return;
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
        widget.formData.city = 'Twoja lokalizacja';
        _addressController.text = 'Współrzędne: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        widget.onDataChanged(widget.formData);
        widget.onAddressSelected?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokalizacja zapisana. Uzupełnij województwo jeśli potrzeba.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      widget.formData.formattedAddress = details.formattedAddress;
      final parts = details.formattedAddress.split(',');
      widget.formData.city = details.locality?.trim().isNotEmpty == true
          ? details.locality
          : (parts.isNotEmpty ? parts.first.trim() : details.formattedAddress);
      widget.formData.voivodeship = _normalizeVoivodeship(details.administrativeArea);
      widget.formData.latitude = details.latitude;
      widget.formData.longitude = details.longitude;
      _addressController.text = details.formattedAddress;
      widget.onDataChanged(widget.formData);
      widget.onAddressSelected?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokalizacja ustawiona – przechodzimy dalej.'),
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
                'Wpisz dokładny adres – po wyborze z listy przejdziemy dalej.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: _isResolvingLocation ? null : _useMyLocation,
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
              const SizedBox(height: AppSpacing.lg),
              Text(
                'LUB wpisz adres (autouzupełnianie):',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              CompositedTransformTarget(
                link: _layerLink,
                child: TextFormField(
                  controller: _addressController,
                  onChanged: _onAddressTextChanged,
                  onTap: () {
                    if (_predictions.isNotEmpty) setState(() => _showOverlay = true);
                  },
                  decoration: InputDecoration(
                    labelText: 'Adres lub miejscowość *',
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
                        : const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: widget.formData.voivodeship != null &&
                        _voivodeships.contains(widget.formData.voivodeship!.toLowerCase())
                    ? widget.formData.voivodeship!.toLowerCase()
                    : null,
                decoration: InputDecoration(
                  labelText: 'Województwo',
                  border: const OutlineInputBorder(),
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
                onChanged: (v) {
                  widget.formData.voivodeship = v;
                  widget.onDataChanged(widget.formData);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Dokładny adres nie będzie publikowany bez Twojej zgody – pokazujemy tylko rejon',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_showOverlay && _predictions.isNotEmpty)
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
