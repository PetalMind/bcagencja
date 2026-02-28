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
      name: 'Jan Kowalski (Inwestor)',
      preview: 'Czy nieruchomość przy ul. Marynarskiej jest nadal dostępna?',
      date: 'Dzisiaj, 14:32',
      unread: true,
      senderType: _SenderType.investor,
    ),
    _Conversation(
      name: 'BC Agencja – Powiadomienie systemowe',
      preview: 'Twoje ogłoszenie zostało zatwierdzone i jest widoczne w wyszukiwarce.',
      date: 'Wczoraj',
      unread: false,
      senderType: _SenderType.system,
    ),
    _Conversation(
      name: 'Anna Nowak (Potencjalny kupujący)',
      preview: 'Proszę o kontakt w sprawie oferty biurowca w Mokotowie.',
      date: '2 dni temu',
      unread: true,
      senderType: _SenderType.buyer,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Wiadomości od potencjalnych kupujących, inwestorów zainteresowanych Twoimi ofertami oraz powiadomienia systemowe od BC Agencja.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (conversations.isEmpty)
            DashboardEmptyState(
              title: 'Brak wiadomości',
              subtitle: 'Wiadomości od potencjalnych kupujących, inwestorów i powiadomienia systemowe pojawią się tutaj.',
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
                  senderType: c.senderType,
                  onTap: () {},
                );
              },
            ),
        ],
      ),
    );
  }
}

enum _SenderType { investor, buyer, system }

class _Conversation {
  const _Conversation({
    required this.name,
    required this.preview,
    required this.date,
    required this.unread,
    required this.senderType,
  });
  final String name;
  final String preview;
  final String date;
  final bool unread;
  final _SenderType senderType;
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.name,
    required this.preview,
    required this.date,
    required this.unread,
    required this.isMobile,
    required this.onTap,
    required this.senderType,
  });

  final String name;
  final String preview;
  final String date;
  final bool unread;
  final bool isMobile;
  final VoidCallback onTap;
  final _SenderType senderType;

  IconData get _avatarIcon {
    switch (senderType) {
      case _SenderType.system:
        return Icons.notifications_rounded;
      case _SenderType.investor:
        return Icons.trending_up_rounded;
      case _SenderType.buyer:
        return Icons.person_rounded;
    }
  }

  Color get _avatarColor {
    switch (senderType) {
      case _SenderType.system:
        return AppColors.primaryDark;
      case _SenderType.investor:
        return AppColors.accent;
      case _SenderType.buyer:
        return AppColors.accent;
    }
  }

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
                backgroundColor: _avatarColor.withValues(alpha: 0.2),
                child: senderType == _SenderType.system
                    ? Icon(_avatarIcon, size: 20, color: _avatarColor)
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: _avatarColor,
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
