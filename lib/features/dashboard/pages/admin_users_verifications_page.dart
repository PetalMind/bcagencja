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

/// Filtr weryfikacji: wszyscy | tylko teaser | tylko identity verified | tylko VDR.
enum _VerificationFilter {
  all,
  teaser,
  identityVerified,
  vdr,
}

/// Panel admina: weryfikacje tożsamości – status NDA, Level 2 (Identity Verified), VDR (Proof of Funds).
/// Zgodnie z docs/WDROZENIE_FUNKCJONALNOSCI.md: Grant Level 2 (NDA), Grant Level 3 (VDR).
class AdminUsersVerificationsPage extends ConsumerStatefulWidget {
  const AdminUsersVerificationsPage({super.key});

  @override
  ConsumerState<AdminUsersVerificationsPage> createState() =>
      _AdminUsersVerificationsPageState();
}

class _AdminUsersVerificationsPageState
    extends ConsumerState<AdminUsersVerificationsPage> {
  _VerificationFilter _filter = _VerificationFilter.all;

  List<AdminUserRecord> _filtered(List<AdminUserRecord> list) {
    switch (_filter) {
      case _VerificationFilter.teaser:
        return list.where((u) => u.accessLevel == 'teaser').toList();
      case _VerificationFilter.identityVerified:
        return list
            .where((u) =>
                u.accessLevel == 'identityVerified' ||
                (u.ndaAcceptedAt != null && u.accessLevel != 'vdr'))
            .toList();
      case _VerificationFilter.vdr:
        return list
            .where((u) =>
                u.accessLevel == 'vdr' ||
                (u.vdrAccessForListingIds.isNotEmpty))
            .toList();
      case _VerificationFilter.all:
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(_adminServiceProvider);
    final isMobile =
        MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Weryfikacje tożsamości',
      currentRoute: AppRouter.dashboardAdminPanel('users-verifications'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status weryfikacji, NDA, Proof of Funds (VDR). Filtruj według poziomu dostępu.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFilterChips(context),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<List<AdminUserRecord>>(
            stream: service.streamUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }
              final list = _filtered(snapshot.data ?? []);
              if (list.isEmpty) {
                return DashboardEmptyState(
                  title: _filter == _VerificationFilter.all
                      ? 'Brak użytkowników'
                      : 'Brak użytkowników dla wybranego filtra',
                  subtitle: _filter == _VerificationFilter.all
                      ? 'Użytkownicy pojawią się po rejestracji.'
                      : 'Zmień filtr lub poczekaj na nowe konta.',
                  icon: Icons.verified_user_outlined,
                );
              }
              return isMobile
                  ? _buildMobileList(list)
                  : _buildDesktopTable(list);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    const filters = [
      (_VerificationFilter.all, 'Wszyscy'),
      (_VerificationFilter.teaser, 'Teaser'),
      (_VerificationFilter.identityVerified, 'Identity Verified'),
      (_VerificationFilter.vdr, 'VDR'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters
          .map(
            (f) => ChoiceChip(
              label: Text(f.$2),
              selected: _filter == f.$1,
              onSelected: (selected) {
                if (selected) setState(() => _filter = f.$1);
              },
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
            ),
          )
          .toList(),
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

  Widget _buildMobileList(List<AdminUserRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _VerificationCard(record: list[index]),
    );
  }

  Widget _buildDesktopTable(List<AdminUserRecord> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Nazwa')),
          DataColumn(label: Text('Rola')),
          DataColumn(label: Text('NDA')),
          DataColumn(label: Text('Level 2')),
          DataColumn(label: Text('VDR')),
        ],
        rows: list
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(Text(r.email ?? '—')),
                  DataCell(Text(r.displayName ?? '—')),
                  DataCell(Chip(
                    label: Text(r.roleLabel, style: AppTextStyles.labelSmall),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
                  DataCell(Text(_formatNda(r.ndaAcceptedAt))),
                  DataCell(_level2Chip(r)),
                  DataCell(Text(_vdrSummary(r))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatNda(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Widget _level2Chip(AdminUserRecord r) {
    final ok = r.isIdentityVerified;
    return Chip(
      label: Text(
        ok ? 'Tak' : 'Nie',
        style: AppTextStyles.labelSmall.copyWith(
          color: ok ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: ok ? AppColors.success.withValues(alpha: 0.12) : null,
    );
  }

  String _vdrSummary(AdminUserRecord r) {
    final count = r.vdrAccessForListingIds.length;
    if (count == 0) return 'Brak';
    return '$count ${count == 1 ? 'oferta' : count < 5 ? 'oferty' : 'ofert'}';
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.record});

  final AdminUserRecord record;

  String _formatNda(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _vdrSummary(AdminUserRecord r) {
    final count = r.vdrAccessForListingIds.length;
    if (count == 0) return 'Brak';
    return '$count ${count == 1 ? 'oferta' : count < 5 ? 'oferty' : 'ofert'}';
  }

  @override
  Widget build(BuildContext context) {
    final ok = record.isIdentityVerified;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.email ?? record.id,
            style: AppTextStyles.labelLarge,
          ),
          if (record.displayName != null && record.displayName!.isNotEmpty)
            Text(
              record.displayName!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(record.roleLabel, style: AppTextStyles.labelSmall),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: Text(
                  'NDA: ${_formatNda(record.ndaAcceptedAt)}',
                  style: AppTextStyles.labelSmall,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: Text(
                  ok ? 'Level 2: Tak' : 'Level 2: Nie',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: ok ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: ok ? AppColors.success.withValues(alpha: 0.12) : null,
              ),
              Chip(
                label: Text('VDR: ${_vdrSummary(record)}', style: AppTextStyles.labelSmall),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
