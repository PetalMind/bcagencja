import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/services/google_places_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

/// Mapa Google Maps z zaznaczoną lokalizacją produktu.
/// Działa na web i mobile. Wymaga skonfigurowanego googleMapsApiKey w AppConfig
/// oraz skryptu Maps JavaScript API w web/index.html (dla web).
class PropertyMap extends StatefulWidget {
  final Property property;
  final double height;

  const PropertyMap({
    super.key,
    required this.property,
    this.height = 300,
  });

  @override
  State<PropertyMap> createState() => _PropertyMapState();
}

class _PropertyMapState extends State<PropertyMap> {
  static const double _defaultLat = 52.2297;
  static const double _defaultLng = 21.0122;
  static const double _defaultZoom = 15.0;

  final GooglePlacesService _placesService = GooglePlacesService();
  LatLng? _position;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolvePosition();
  }

  Future<void> _resolvePosition() async {
    final key = AppConfig.googleMapsApiKey;
    if (key.isEmpty || key == 'YOUR_GOOGLE_MAPS_API_KEY') {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Skonfiguruj Google Maps API key w AppConfig';
        });
      }
      return;
    }

    double? lat = widget.property.latitude;
    double? lng = widget.property.longitude;

    if (lat != null && lng != null) {
      if (mounted) {
        setState(() {
          _position = LatLng(lat, lng);
          _loading = false;
        });
      }
      return;
    }

    final address = _buildAddress();
    if (address.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Brak adresu do geokodowania';
        });
      }
      return;
    }

    final details = await _placesService.geocodeFromAddress(address);
    if (mounted) {
      setState(() {
        _loading = false;
        if (details?.latitude != null && details?.longitude != null) {
          _position = LatLng(details!.latitude!, details.longitude!);
        } else {
          _error = 'Nie udało się ustalić lokalizacji';
        }
      });
    }
  }

  String _buildAddress() {
    final parts = <String>[];
    if (widget.property.street != null && widget.property.street!.trim().isNotEmpty) {
      parts.add(widget.property.street!.trim());
    }
    if (widget.property.district != null && widget.property.district!.trim().isNotEmpty) {
      parts.add(widget.property.district!.trim());
    }
    if (widget.property.city.isNotEmpty) {
      parts.add(widget.property.city.trim());
    }
    if (parts.isEmpty && widget.property.location.isNotEmpty) {
      parts.add(widget.property.location.trim());
    }
    return parts.join(', ');
  }

  void _openInMaps() {
    final lat = _position?.latitude ?? widget.property.latitude ?? _defaultLat;
    final lng = _position?.longitude ?? widget.property.longitude ?? _defaultLng;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildPlaceholder(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ładowanie mapy...',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null || _position == null) {
      return _buildPlaceholder(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.map, size: 48, color: AppColors.grey400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Mapa Google Maps',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.property.city}, ${widget.property.district ?? ''}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            height: widget.height,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _position!,
                zoom: _defaultZoom,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('property'),
                  position: _position!,
                  infoWindow: InfoWindow(
                    title: widget.property.title,
                    snippet: _buildAddress(),
                  ),
                ),
              },
              onMapCreated: (_) {},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        Positioned(
          bottom: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: InkWell(
              onTap: _openInMaps,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.map, size: 20, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Otwórz w mapach',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder({required Widget child}) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(child: child),
    );
  }
}
