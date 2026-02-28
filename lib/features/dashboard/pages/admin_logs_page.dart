import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../../widgets/common/app_data_grid.dart';

final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Panel admina: logi systemowe (pobrania dokumentów, audyt).
/// Kolekcja document_downloads: userId, listingId, documentId, ip, timestamp.
class AdminLogsPage extends ConsumerWidget {
  const AdminLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(_adminServiceProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Logi systemowe',
      currentRoute: AppRouter.dashboardAdminLogs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historia pobrań dokumentów (VDR). Kto, co, kiedy, z jakiego IP.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<List<AdminLogRecord>>(
            stream: service.streamDocumentDownloads(limit: 100),
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
                  title: 'Brak logów',
                  subtitle: 'Logi pobrań dokumentów pojawią się po wdrożeniu VDR i watermarkingu. '
                      'Kolekcja document_downloads w Firestore.',
                  icon: Icons.history,
                );
              }
              return isMobile ? _buildMobileList(list) : _buildDesktopTable(list);
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
          const SizedBox(height: AppSpacing.md),
          Text(
            'Upewnij się, że kolekcja document_downloads istnieje w Firestore i reguły bezpieczeństwa pozwalają adminowi na odczyt.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<AdminLogRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final r = list[index];
        return ListTile(
          title: Text(r.listingId ?? r.documentId ?? r.userId ?? '—'),
          subtitle: Text(
            '${r.userId ?? '—'} • ${r.ipAddress ?? '—'} • ${r.timestamp != null ? _formatDate(r.timestamp!) : '—'}',
            style: AppTextStyles.bodySmall,
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<AdminLogRecord> list) {
    return AppDataGrid(
      allowSorting: true,
      allowColumnsResizing: true,
      showPagination: list.length > 25,
      pageSize: 25,
      columns: const [
        AppDataGridColumn(name: 'date', label: 'Data', width: 150),
        AppDataGridColumn(name: 'user', label: 'Użytkownik', minimumWidth: 180),
        AppDataGridColumn(name: 'listing', label: 'Oferta', minimumWidth: 140),
        AppDataGridColumn(name: 'document', label: 'Dokument', minimumWidth: 140),
        AppDataGridColumn(name: 'ip', label: 'IP', width: 130),
      ],
      sortValues: list.map((r) => [
        r.timestamp?.millisecondsSinceEpoch ?? 0,
        r.userId ?? '',
        r.listingId ?? '',
        r.documentId ?? '',
        r.ipAddress ?? '',
      ]).toList(),
      rows: list.map((r) => [
        Text(r.timestamp != null ? _formatDateTime(r.timestamp!) : '—'),
        Text(r.userId ?? '—', overflow: TextOverflow.ellipsis),
        Text(r.listingId ?? '—', overflow: TextOverflow.ellipsis),
        Text(r.documentId ?? '—', overflow: TextOverflow.ellipsis),
        Text(r.ipAddress ?? '—'),
      ]).toList(),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String _formatDateTime(DateTime d) => '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
