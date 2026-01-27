import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/property_model.dart';
import 'contact_form.dart';

class PropertyInfoPanel extends StatelessWidget {
  final Property property;
  
  const PropertyInfoPanel({
    super.key,
    required this.property,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppSpacing.mobileBreakpoint;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Price
          Text(
            property.formattedPrice,
            style: AppTextStyles.priceLarge,
          ),
          if (property.pricePerSqm != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${property.pricePerSqm!.toStringAsFixed(0)} zł/m²',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          
          // Parameters
          _buildParameter(AppIcons.area, 'Powierzchnia', '${property.area.toStringAsFixed(0)} m²'),
          _buildParameter(AppIcons.rooms, 'Liczba pokoi', '${property.rooms}'),
          if (property.floor != null)
            _buildParameter(AppIcons.floor, 'Piętro', '${property.floor}'),
          
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          
          // Contact form
          if (!isMobile) const ContactForm(),
          
          // Phone button
          if (property.ownerPhone != null) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(property.ownerPhone!),
              icon: const Icon(AppIcons.phone),
              label: Text(property.ownerPhone!),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ],
          
          // Action buttons
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(AppIcons.favorites),
            label: const Text('Zapisz do ulubionych'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(AppIcons.share),
            label: const Text('Udostępnij'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParameter(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
