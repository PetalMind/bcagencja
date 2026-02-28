import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Max lines of description before showing "Pokaż więcej".
const int _kDescriptionPreviewLines = 4;

/// Minimalna liczba znaków, po której pokazujemy przycisk rozwinięcia.
const int _kMinCharsForExpand = 200;

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
    final needsExpand = widget.description.length > _kMinCharsForExpand ||
        widget.description.split('\n').length > _kDescriptionPreviewLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!needsExpand)
          Text(
            widget.description,
            style: AppTextStyles.bodyLarge,
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: AppTextStyles.bodyLarge,
                  maxLines: _expanded ? null : _kDescriptionPreviewLines,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      right: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Zwiń' : 'Pokaż więcej',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          _expanded ? AppIcons.collapse : AppIcons.expand,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
