import 'package:flutter/material.dart';
import '../../../core/state/models/property_model.dart';
import 'listing_card.dart';
import '../../../core/theme/app_spacing.dart';

class ListingsListView extends StatelessWidget {
  final List<Property> properties;
  
  const ListingsListView({
    super.key,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: properties.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return ListingCard(property: properties[index]);
      },
    );
  }
}
