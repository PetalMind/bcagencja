import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';

class MobileContactBar extends StatelessWidget {
  final String price;
  final String? phone;
  final VoidCallback? onMessageTap;
  
  const MobileContactBar({
    super.key,
    required this.price,
    this.phone,
    this.onMessageTap,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cena',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    price,
                    style: AppTextStyles.priceMedium,
                  ),
                ],
              ),
            ),
            if (phone != null) ...[
              ElevatedButton.icon(
                onPressed: () => _makePhoneCall(phone!),
                icon: const Icon(AppIcons.phone),
                label: const Text('Zadzwoń'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (onMessageTap != null)
              ElevatedButton.icon(
                onPressed: onMessageTap,
                icon: const Icon(AppIcons.message),
                label: const Text('Napisz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
