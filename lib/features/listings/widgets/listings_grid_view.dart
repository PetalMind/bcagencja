import 'package:flutter/material.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/theme/app_spacing.dart';
import 'listing_grid_tile.dart';

class ListingsGridView extends StatelessWidget {
  final List<Property> properties;
  
  const ListingsGridView({
    super.key,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < AppSpacing.mobileBreakpoint
        ? 1
        : screenWidth < AppSpacing.tabletBreakpoint
            ? 2
            : 4;
    
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return ListingGridTile(property: properties[index]);
      },
    );
  }
}
