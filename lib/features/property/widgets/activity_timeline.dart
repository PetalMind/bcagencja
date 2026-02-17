import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/state/models/property_model.dart';
import '../../../core/state/providers/favorites_provider.dart';
import '../../../core/state/providers/smart_favorites_provider.dart';

/// Historia aktywności (mock) – widoczna na stronie szczegółów, gdy oferta jest zapisana.
class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({
    super.key,
    required this.property,
    this.isMobile = false,
  });

  final Property property;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(favoritesProvider).contains(property.id);
    if (!isSaved) return const SizedBox.shrink();

    final entry = ref.watch(smartFavoritesProvider).entryFor(property.id);
    final savedAt = entry?.savedAt ?? DateTime.now();
    final events = _buildMockEvents(property, savedAt, entry?.note);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Historia aktywności',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: events.asMap().entries.map((e) {
                final i = e.key;
                final ev = e.value;
                final isLast = i == events.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: ev.iconColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.grey300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(ev.date),
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(ev.icon, size: 18, color: ev.iconColor),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static List<_TimelineEvent> _buildMockEvents(Property property, DateTime savedAt, String? note) {
    final list = <_TimelineEvent>[];
    final now = DateTime.now();

    list.add(_TimelineEvent(
      date: now.subtract(const Duration(hours: 2)),
      title: 'Dodano nowy dokument: Operat szacunkowy',
      icon: Icons.description_outlined,
      iconColor: AppColors.info,
    ));
    if (note != null && note.isNotEmpty) {
      list.add(_TimelineEvent(
        date: now.subtract(const Duration(days: 2)),
        title: 'Ty: Dodałeś notatkę „${note.length > 40 ? '${note.substring(0, 40)}...' : note}”',
        icon: Icons.comment_outlined,
        iconColor: AppColors.accent,
      ));
    }
    list.add(_TimelineEvent(
      date: savedAt,
      title: 'Ty: Zapisałeś tę ofertę',
      icon: Icons.favorite_rounded,
      iconColor: AppColors.accent,
    ));
    list.add(_TimelineEvent(
      date: savedAt.subtract(const Duration(days: 2)),
      title: 'Cena spadła o 100 tys. PLN',
      icon: Icons.trending_down_rounded,
      iconColor: AppColors.success,
    ));

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.date,
    required this.title,
    required this.icon,
    required this.iconColor,
  });
  final DateTime date;
  final String title;
  final IconData icon;
  final Color iconColor;
}
