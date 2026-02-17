import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/listing_submission_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';

final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Panel admina: moderacja zgłoszeń "Chcę sprzedać".
/// Statusy: Nowe, W trakcie, Zakontraktowane, Odrzucone.
/// Akcje: Przypisz do Agenta, Odrzuć, Skontaktuj się.
class AdminSubmissionsPage extends ConsumerStatefulWidget {
  const AdminSubmissionsPage({super.key});

  @override
  ConsumerState<AdminSubmissionsPage> createState() => _AdminSubmissionsPageState();
}

class _AdminSubmissionsPageState extends ConsumerState<AdminSubmissionsPage> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(_submissionServiceProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Oczekujące – Chcę sprzedać',
      currentRoute: AppRouter.dashboardAdminSubmissions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(context, isMobile),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<List<ListingSubmissionRecord>>(
            stream: service.streamSubmissions(statusFilter: _statusFilter),
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
                  title: 'Brak zgłoszeń',
                  subtitle: _statusFilter != null
                      ? 'Brak zgłoszeń o wybranym statusie.'
                      : 'Zgłoszenia z formularza "Chcę sprzedać" pojawią się tutaj.',
                  icon: Icons.real_estate_agent_outlined,
                );
              }
              return isMobile ? _buildMobileList(list) : _buildDesktopTable(list);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    const options = [
      (null, 'Wszystkie'),
      ('pending', 'Nowe'),
      ('in_progress', 'W trakcie'),
      ('contracted', 'Zakontraktowane'),
      ('rejected', 'Odrzucone'),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options
          .map((o) => ChoiceChip(
                label: Text(o.$2),
                selected: _statusFilter == o.$1,
                onSelected: (_) => setState(() => _statusFilter = o.$1),
              ))
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

  Widget _buildMobileList(List<ListingSubmissionRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _SubmissionCard(
        record: list[index],
        onAssign: () => _showAssignDialog(context, list[index]),
        onReject: () => _showRejectDialog(context, list[index]),
        onContact: () => _launchContact(list[index]),
      ),
    );
  }

  Widget _buildDesktopTable(List<ListingSubmissionRecord> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Typ')),
          DataColumn(label: Text('Lokalizacja')),
          DataColumn(label: Text('Kontakt')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Akcje')),
        ],
        rows: list.map((r) => _buildTableRow(r)).toList(),
      ),
    );
  }

  DataRow _buildTableRow(ListingSubmissionRecord r) {
    return DataRow(
      cells: [
        DataCell(Text(r.createdAt != null
            ? '${r.createdAt!.day}.${r.createdAt!.month}.${r.createdAt!.year}'
            : '—')),
        DataCell(Text(r.assetType == 'land' ? 'Grunt' : r.assetType ?? '—')),
        DataCell(Text('${r.city ?? ''} ${r.voivodeship ?? ''}'.trim().isEmpty ? '—' : '${r.city ?? ''}, ${r.voivodeship ?? ''}')),
        DataCell(Text('${r.contactName ?? ''} (${r.contactEmail ?? ''})')),
        DataCell(
          Chip(
            label: Text(r.statusLabel, style: AppTextStyles.labelSmall),
            backgroundColor: _statusColor(r.status).withValues(alpha: 0.2),
          ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _showAssignDialog(context, r),
              child: const Text('Przypisz'),
            ),
            TextButton(
              onPressed: () => _showRejectDialog(context, r),
              child: const Text('Odrzuć'),
            ),
            IconButton(
              icon: const Icon(Icons.email_outlined),
              onPressed: () => _launchContact(r),
              tooltip: 'Skontaktuj się',
            ),
          ],
        )),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.info;
      case 'in_progress': return AppColors.warning;
      case 'contracted': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.grey600;
    }
  }

  void _showAssignDialog(BuildContext context, ListingSubmissionRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przypisz do Agenta'),
        content: const Text(
          'Funkcja przypisania do agenta wymaga listy agentów z Firestore. '
          'W kolejnej iteracji: wybór agenta z listy, zapis assignedToAgentId.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij')),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ListingSubmissionRecord record) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odrzuć zgłoszenie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Opcjonalny powód odrzucenia:'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Powód (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(
            onPressed: () async {
              final service = ref.read(_submissionServiceProvider);
              await service.updateStatus(
                record.id,
                ListingSubmissionService.statusRejected,
                rejectionReason: controller.text.trim().isEmpty ? null : controller.text.trim(),
              );
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Odrzuć'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchContact(ListingSubmissionRecord record) async {
    final email = record.contactEmail;
    if (email == null || email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  final ListingSubmissionRecord record;
  final VoidCallback onAssign;
  final VoidCallback onReject;
  final VoidCallback onContact;

  const _SubmissionCard({
    required this.record,
    required this.onAssign,
    required this.onReject,
    required this.onContact,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.contactName ?? '—',
                  style: AppTextStyles.titleMedium,
                ),
                Chip(
                  label: Text(record.statusLabel, style: AppTextStyles.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${record.assetType == 'land' ? 'Grunt' : 'Nieruchomość'} – ${record.city ?? ''}, ${record.voivodeship ?? ''}'),
            if (record.contactEmail != null) Text(record.contactEmail!),
            if (record.contactPhone != null) Text(record.contactPhone!),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(onPressed: onAssign, child: const Text('Przypisz')),
                TextButton(onPressed: onReject, child: const Text('Odrzuć')),
                TextButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.email, size: 18),
                  label: const Text('Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
