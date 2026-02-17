import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Tekst watermarka wyświetlany na zdjęciach portalu.
const String kImageWatermarkText = 'bcagencja.eu';

/// Nakładka z watermarkiem „bcagencja.eu” – do użycia w Stack nad zdjęciem.
/// Umieszczona w prawym dolnym rogu, półprzezroczyste tło dla czytelności.
class ImageWatermarkOverlay extends StatelessWidget {
  const ImageWatermarkOverlay({
    super.key,
    this.text = kImageWatermarkText,
    this.fontSize = 12,
    this.padding = AppSpacing.sm,
  });

  final String text;
  final double fontSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: padding,
      bottom: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Opakowuje dowolne zdjęcie (child) i nakłada na nie watermark „bcagencja.eu”.
/// Używaj dla wszystkich zdjęć ofert na portalu.
class WatermarkedImage extends StatelessWidget {
  const WatermarkedImage({
    super.key,
    required this.child,
    this.watermarkText = kImageWatermarkText,
    this.fontSize = 12,
  });

  final Widget child;
  final String watermarkText;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.antiAlias,
      children: [
        child,
        ImageWatermarkOverlay(
          text: watermarkText,
          fontSize: fontSize,
        ),
      ],
    );
  }
}
