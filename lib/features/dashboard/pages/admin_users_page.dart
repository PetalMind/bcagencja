import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';

final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Panel admina: zarządzanie użytkownikami (lista, zmiana roli).
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(_adminServiceProvider);
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
              return isMobile ? _buildMobileList(context, ref, list) : _buildDesktopTable(context, ref, list);
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

  Widget _buildMobileList(BuildContext context, WidgetRef ref, List<AdminUserRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _UserCard(
        record: list[index],
        onRoleTap: () => _showRoleDialog(context, ref, list[index]),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, WidgetRef ref, List<AdminUserRecord> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Nazwa')),
          DataColumn(label: Text('Rola')),
          DataColumn(label: Text('Region')),
          DataColumn(label: Text('Akcje')),
        ],
        rows: list.map((r) => DataRow(
          cells: [
            DataCell(Text(r.email ?? '—')),
            DataCell(Text(r.displayName ?? '—')),
            DataCell(Chip(label: Text(r.roleLabel, style: AppTextStyles.labelSmall))),
            DataCell(Text(r.regionVoivodeship ?? '—')),
            DataCell(
              TextButton(
                onPressed: () => _showRoleDialog(context, ref, r),
                child: const Text('Zmień rolę'),
              ),
            ),
          ],
        )).toList(),
      ),
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
}

class _UserCard extends StatelessWidget {
  final AdminUserRecord record;
  final VoidCallback onRoleTap;

  const _UserCard({required this.record, required this.onRoleTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(record.displayName ?? record.email ?? record.id),
        subtitle: Text(record.email ?? '—'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(label: Text(record.roleLabel, style: AppTextStyles.labelSmall)),
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onRoleTap, child: const Text('Zmień rolę')),
          ],
        ),
      ),
    );
  }
}
