import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icons.dart';

class BasicSearchBar extends StatelessWidget {
  final VoidCallback? onSearch;
  
  const BasicSearchBar({
    super.key,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Row(
        children: [
          const Icon(AppIcons.search, color: AppColors.grey600),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Szukaj mieszkania, domu, działki...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.grey400),
              ),
              onSubmitted: (_) => onSearch?.call(),
            ),
          ),
          ElevatedButton(
            onPressed: onSearch,
            child: const Text('Szukaj'),
          ),
        ],
      ),
    );
  }
}
