import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icons.dart';

enum ViewMode {
  list,
  grid,
  map,
}

class ViewToggle extends StatelessWidget {
  final ViewMode selectedView;
  final Function(ViewMode) onViewChanged;
  
  const ViewToggle({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(ViewMode.list, AppIcons.viewList),
          const SizedBox(width: 4),
          _buildButton(ViewMode.grid, AppIcons.viewGrid),
          const SizedBox(width: 4),
          _buildButton(ViewMode.map, AppIcons.viewMap),
        ],
      ),
    );
  }
  
  Widget _buildButton(ViewMode mode, IconData icon) {
    final isSelected = selectedView == mode;
    
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? AppColors.white : AppColors.grey600,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? AppColors.accent : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
      onPressed: () => onViewChanged(mode),
    );
  }
}
