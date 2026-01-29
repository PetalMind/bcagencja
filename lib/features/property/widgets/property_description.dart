import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Max lines of description before showing "Pokaż więcej".
const int _kDescriptionPreviewLines = 4;

class PropertyDescription extends StatefulWidget {
  final String title;
  final String description;

  const PropertyDescription({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<PropertyDescription> createState() => _PropertyDescriptionState();
}

class _PropertyDescriptionState extends State<PropertyDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final needsExpand = widget.description.length > 200 ||
        widget.description.split('\n').length > _kDescriptionPreviewLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            if (!needsExpand) {
              return Text(
                widget.description,
                style: AppTextStyles.bodyLarge,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: AppTextStyles.bodyLarge,
                  maxLines: _expanded ? null : _kDescriptionPreviewLines,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Pokaż mniej' : 'Pokaż więcej',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
