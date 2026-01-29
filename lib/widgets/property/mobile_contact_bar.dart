import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../widgets/common/custom_button.dart';

/// Dolny pasek na mobile: cena + CTA (Zadzwoń, Napisz).
/// Mobile-first: duża cena, przyciski CustomButton, SafeArea.
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    price,
                    style: AppTextStyles.priceMedium.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
            if (phone != null) ...[
              CustomButton(
                label: 'Zadzwoń',
                icon: AppIcons.phone,
                onPressed: () => _makePhoneCall(phone!),
                variant: ButtonVariant.outlined,
                size: ButtonSize.small,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (onMessageTap != null)
              CustomButton(
                label: 'Napisz',
                icon: AppIcons.message,
                onPressed: onMessageTap,
                variant: ButtonVariant.primary,
                size: ButtonSize.small,
              ),
          ],
        ),
      ),
    );
  }
}
