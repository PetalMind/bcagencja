import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static const List<_Conversation> _mockConversations = [
    _Conversation(
      name: 'Jan Kowalski',
      preview: 'Czy nieruchomość przy ul. Marynarskiej jest nadal dostępna?',
      date: 'Dzisiaj, 14:32',
      unread: true,
    ),
    _Conversation(
      name: 'BC Agencja',
      preview: 'Twoje ogłoszenie zostało zatwierdzone i jest widoczne w wyszukiwarce.',
      date: 'Wczoraj',
      unread: false,
    ),
    _Conversation(
      name: 'Anna Nowak',
      preview: 'Proszę o kontakt w sprawie oferty biurowca w Mokotowie.',
      date: '2 dni temu',
      unread: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final conversations = _mockConversations;

    return DashboardScaffold(
      title: 'Wiadomości',
      currentRoute: AppRouter.dashboardMessages,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${conversations.length} wątków',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (conversations.isEmpty)
            DashboardEmptyState(
              title: 'Brak wiadomości',
              subtitle: 'Wiadomości od potencjalnych kupujących i od nas pojawią się tutaj.',
              actionLabel: 'Przejdź do ogłoszeń',
              icon: AppIcons.message,
              actionIcon: AppIcons.office,
              onAction: () => context.go(AppRouter.dashboardListings),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final c = conversations[index];
                return _MessageTile(
                  name: c.name,
                  preview: c.preview,
                  date: c.date,
                  unread: c.unread,
                  isMobile: isMobile,
                  onTap: () {},
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Conversation {
  const _Conversation({
    required this.name,
    required this.preview,
    required this.date,
    required this.unread,
  });
  final String name;
  final String preview;
  final String date;
  final bool unread;
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.name,
    required this.preview,
    required this.date,
    required this.unread,
    required this.isMobile,
    required this.onTap,
  });

  final String name;
  final String preview;
  final String date;
  final bool unread;
  final bool isMobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderLight),
            color: unread ? AppColors.accent.withValues(alpha: 0.04) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                AppIcons.chevronRight,
                size: 20,
                color: AppColors.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
