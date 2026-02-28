import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../../widgets/common/app_data_grid.dart';

final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Panel admina: zarządzanie użytkownikami (lista, zmiana roli).
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(_adminServiceProvider);
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.id;
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Użytkownicy',
      currentRoute: AppRouter.dashboardAdminUsers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lista użytkowników. Zmiana roli wymaga uprawnień admin w Firestore.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<List<AdminUserRecord>>(
            stream: service.streamUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return DashboardEmptyState(
                  title: 'Brak użytkowników',
                  subtitle: 'Użytkownicy pojawią się po rejestracji.',
                  icon: Icons.people_outline,
                );
              }
              return isMobile
                  ? _buildMobileList(context, ref, list, currentUserId)
                  : _buildDesktopTable(context, ref, list, currentUserId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    WidgetRef ref,
    List<AdminUserRecord> list,
    String? currentUserId,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final r = list[index];
        final isSelf = r.id == currentUserId;
        return _UserCard(
          record: r,
          isSelf: isSelf,
          onRoleTap: () => _showRoleDialog(context, ref, r),
          onBlockTap: () => _showBlockDialog(context, ref, r),
          onDeleteTap: () => _showDeleteDialog(context, ref, r),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<AdminUserRecord> list,
    String? currentUserId,
  ) {
    return AppDataGrid(
      allowSorting: true,
      allowColumnsResizing: true,
      showPagination: list.length > 25,
      pageSize: 25,
      columns: const [
        AppDataGridColumn(name: 'email', label: 'Email', minimumWidth: 180),
        AppDataGridColumn(name: 'name', label: 'Nazwa', minimumWidth: 140),
        AppDataGridColumn(name: 'role', label: 'Rola', width: 120),
        AppDataGridColumn(name: 'status', label: 'Status', width: 130),
        AppDataGridColumn(name: 'region', label: 'Region', minimumWidth: 130),
        AppDataGridColumn(name: 'actions', label: 'Akcje', width: 230, sortable: false),
      ],
      sortValues: list.map((r) => [
        r.email ?? '',
        r.displayName ?? '',
        r.roleLabel,
        r.blocked ? 'Zablokowany' : '',
        r.regionVoivodeship ?? '',
        0,
      ]).toList(),
      rows: list.map((r) {
        final isSelf = r.id == currentUserId;
        return [
          Text(r.email ?? '—', overflow: TextOverflow.ellipsis),
          Text(r.displayName ?? '—', overflow: TextOverflow.ellipsis),
          Chip(label: Text(r.roleLabel, style: AppTextStyles.labelSmall)),
          r.blocked
              ? Chip(
                  label: Text('Zablokowany', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                  backgroundColor: AppColors.error.withValues(alpha: 0.12),
                )
              : const Text('—'),
          Text(r.regionVoivodeship ?? '—', overflow: TextOverflow.ellipsis),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _showRoleDialog(context, ref, r),
                child: const Text('Rola'),
              ),
              TextButton(
                onPressed: isSelf ? null : () => _showBlockDialog(context, ref, r),
                child: Text(r.blocked ? 'Odblokuj' : 'Zablokuj'),
              ),
              TextButton(
                onPressed: isSelf ? null : () => _showDeleteDialog(context, ref, r),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Usuń'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, AdminUserRecord record) {
    const roles = ['lead', 'agent', 'director', 'admin'];
    const roleLabels = ['Inwestor', 'Agent', 'Dyrektor', 'Administrator'];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Zmień rolę: ${record.displayName ?? record.email ?? record.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < roles.length; i++)
              ListTile(
                title: Text(roleLabels[i]),
                leading: Radio<String>(
                  value: roles[i],
                  groupValue: record.role,
                  onChanged: (v) async {
                    if (v == null) return;
                    final service = ref.read(_adminServiceProvider);
                    await service.updateUserRole(record.id, v);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
                onTap: () async {
                  final service = ref.read(_adminServiceProvider);
                  await service.updateUserRole(record.id, roles[i]);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, WidgetRef ref, AdminUserRecord record) {
    final blocked = record.blocked;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(blocked ? 'Odblokować konto?' : 'Zablokować konto?'),
        content: Text(
          blocked
              ? 'Użytkownik ${record.displayName ?? record.email ?? record.id} będzie mógł ponownie logować się do aplikacji.'
              : 'Użytkownik ${record.displayName ?? record.email ?? record.id} nie będzie mógł się logować do momentu odblokowania.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              final service = ref.read(_adminServiceProvider);
              final err = await service.setUserBlocked(record.id, !blocked);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd: $err'), backgroundColor: AppColors.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(blocked ? 'Konto odblokowane.' : 'Konto zablokowane.')),
                );
              }
            },
            child: Text(blocked ? 'Odblokuj' : 'Zablokuj'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, AdminUserRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć konto użytkownika?'),
        content: Text(
          'Ta operacja usunie profil użytkownika ${record.displayName ?? record.email ?? record.id} z bazy. '
          'Konto Firebase Auth (logowanie) może nadal istnieć – pełne usunięcie wymaga Cloud Function. '
          'Czy na pewno chcesz usunąć?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final service = ref.read(_adminServiceProvider);
              final err = await service.deleteUser(record.id);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd: $err'), backgroundColor: AppColors.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil użytkownika usunięty.')),
                );
              }
            },
            child: const Text('Usuń konto'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserRecord record;
  final bool isSelf;
  final VoidCallback onRoleTap;
  final VoidCallback onBlockTap;
  final VoidCallback onDeleteTap;

  const _UserCard({
    required this.record,
    required this.isSelf,
    required this.onRoleTap,
    required this.onBlockTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.displayName ?? record.email ?? record.id,
                        style: AppTextStyles.titleSmall,
                      ),
                      if (record.email != null) Text(record.email!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (record.blocked)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Chip(
                      label: Text('Zablokowany', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    ),
                  ),
                Chip(label: Text(record.roleLabel, style: AppTextStyles.labelSmall)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton(onPressed: onRoleTap, child: const Text('Zmień rolę')),
                TextButton(
                  onPressed: isSelf ? null : onBlockTap,
                  child: Text(record.blocked ? 'Odblokuj' : 'Zablokuj'),
                ),
                TextButton(
                  onPressed: isSelf ? null : onDeleteTap,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Usuń konto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
