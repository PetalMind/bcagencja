import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PropertyDescription extends StatelessWidget {
  final String title;
  final String description;
  
  const PropertyDescription({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          description,
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}
