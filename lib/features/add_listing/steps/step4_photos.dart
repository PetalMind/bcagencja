import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/state/models/listing_form_model.dart';

class Step4Photos extends StatefulWidget {
  final ListingFormData formData;
  final Function(ListingFormData) onDataChanged;

  const Step4Photos({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step4Photos> createState() => _Step4PhotosState();
}

class _Step4PhotosState extends State<Step4Photos> {
  void _addPhoto() {
    setState(() {
      widget.formData.images.add('zdjecie_${widget.formData.images.length + 1}');
      widget.onDataChanged(widget.formData);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      widget.formData.images.removeAt(index);
      widget.onDataChanged(widget.formData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.formData.images;
    final hasError = images.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zdjęcia', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dodaj minimum jedno zdjęcie. Zalecane: min. 800×600 px, format JPG lub PNG.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dodaj co najmniej jedno zdjęcie.',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (images.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.image,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            child: Text(
                              'Zdjęcie ${index + 1}',
                              style: AppTextStyles.labelSmall,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: IconButton(
                        icon: const Icon(AppIcons.delete, color: AppColors.error),
                        onPressed: () => _removePhoto(index),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.white,
                          padding: const EdgeInsets.all(AppSpacing.xs),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(AppIcons.add),
            label: const Text('Dodaj zdjęcie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
