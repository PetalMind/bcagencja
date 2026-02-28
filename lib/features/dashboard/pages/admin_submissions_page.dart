import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/listing_submission_service.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/empty_state.dart';
import '../../../widgets/common/app_data_grid.dart';

final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());
final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// Lista agentów do wyboru przy przypisywaniu zgłoszeń.
final _agentsProvider = FutureProvider<List<AdminUserRecord>>((ref) {
  return ref.read(_adminServiceProvider).getAgents();
});

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

  Map<String, String> _agentsNameMap() {
    final agents = ref.watch(_agentsProvider).asData?.value ?? [];
    final map = <String, String>{};
    for (final a in agents) {
      map[a.id] = a.displayName?.trim().isNotEmpty == true ? a.displayName! : (a.email ?? a.id);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(_submissionServiceProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final agentsMap = _agentsNameMap();

    return DashboardScaffold(
      title: 'Zgłoszenia do sprzedaży',
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
              return isMobile
                  ? _buildMobileList(list, agentsMap)
                  : _buildDesktopTable(list, agentsMap);
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
      ('published', 'Udostępnione'),
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

  Widget _buildMobileList(List<ListingSubmissionRecord> list, Map<String, String> agentsMap) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final r = list[index];
        return _SubmissionCard(
          record: r,
          assignedAgentName: r.assignedToAgentId != null ? agentsMap[r.assignedToAgentId] ?? r.assignedToAgentId : null,
          onPreview: () => context.push(AppRouter.dashboardAdminSubmissionsPreview, extra: r),
          onAssign: r.assignedToAgentId == null ? () => _showAssignDialog(context, r) : null,
          onShareForSale: r.assignedToAgentId != null && r.status != ListingSubmissionService.statusPublished
              ? () => _shareForSale(context, r)
              : null,
          onReject: () => _showRejectDialog(context, r),
          onContact: () => _launchContact(r),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<ListingSubmissionRecord> list, Map<String, String> agentsMap) {
    return AppDataGrid(
      allowSorting: true,
      allowColumnsResizing: true,
      showPagination: list.length > 20,
      pageSize: 20,
      columns: const [
        AppDataGridColumn(name: 'ref', label: 'Nr ref.', width: 110),
        AppDataGridColumn(name: 'date', label: 'Data', width: 90),
        AppDataGridColumn(name: 'type', label: 'Typ', width: 100),
        AppDataGridColumn(name: 'location', label: 'Lokalizacja', minimumWidth: 130),
        AppDataGridColumn(name: 'areaPrice', label: 'Pow. / Cena', width: 130),
        AppDataGridColumn(name: 'contact', label: 'Kontakt', minimumWidth: 160),
        AppDataGridColumn(name: 'status', label: 'Status', width: 110),
        AppDataGridColumn(name: 'agent', label: 'Przypisany do', minimumWidth: 130),
        AppDataGridColumn(name: 'actions', label: 'Akcje', width: 270, sortable: false),
      ],
      sortValues: list.map((r) {
        final loc = '${r.city ?? ''}${r.voivodeship != null ? ', ${r.voivodeship}' : ''}'.trim();
        return [
          r.referenceNumber,
          r.createdAt?.millisecondsSinceEpoch ?? 0,
          r.typeShortLabel,
          loc,
          r.expectedPrice ?? 0.0,
          r.contactName ?? '',
          r.statusLabel,
          r.assignedToAgentId != null ? (agentsMap[r.assignedToAgentId] ?? '') : '',
          0,
        ];
      }).toList(),
      rows: list.map((r) => _buildTableRowWidgets(r, agentsMap)).toList(),
    );
  }

  List<Widget> _buildTableRowWidgets(ListingSubmissionRecord r, Map<String, String> agentsMap) {
    final loc = '${r.city ?? ''}${r.voivodeship != null ? ', ${r.voivodeship}' : ''}'.trim();
    final areaPrice = [
      if (r.area != null && r.area! > 0) '${r.area!.toStringAsFixed(0)} m²',
      if (r.expectedPrice != null && r.expectedPrice! > 0) _formatPrice(r.expectedPrice!),
    ].join(' / ');
    return [
      Text(r.referenceNumber, style: AppTextStyles.labelSmall),
      Text(r.createdAt != null
          ? '${r.createdAt!.day.toString().padLeft(2, '0')}.${r.createdAt!.month.toString().padLeft(2, '0')}.${r.createdAt!.year}'
          : '—'),
      Text(r.typeShortLabel),
      Text(loc.isEmpty ? '—' : loc, overflow: TextOverflow.ellipsis),
      Text(areaPrice.isEmpty ? '—' : areaPrice),
      Text('${r.contactName ?? ''} (${r.contactEmail ?? ''})', overflow: TextOverflow.ellipsis),
      Chip(
        label: Text(r.statusLabel, style: AppTextStyles.labelSmall),
        backgroundColor: _statusColor(r.status).withValues(alpha: 0.2),
      ),
      Text(
        r.assignedToAgentId != null ? (agentsMap[r.assignedToAgentId] ?? r.assignedToAgentId!) : '—',
        style: AppTextStyles.labelSmall,
        overflow: TextOverflow.ellipsis,
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.push(AppRouter.dashboardAdminSubmissionsPreview, extra: r),
            child: const Text('Podgląd'),
          ),
          if (r.assignedToAgentId != null && r.status != ListingSubmissionService.statusPublished)
            TextButton(
              onPressed: () => _shareForSale(context, r),
              child: const Text('Udostępnij'),
            )
          else if (r.assignedToAgentId == null)
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
      ),
    ];
  }

  String _formatPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M zł';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} tys. zł';
    return '${v.toStringAsFixed(0)} zł';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.info;
      case 'in_progress': return AppColors.warning;
      case 'published': return AppColors.success;
      case 'contracted': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.grey600;
    }
  }

  Future<void> _shareForSale(BuildContext context, ListingSubmissionRecord record) async {
    try {
      final service = ref.read(_submissionServiceProvider);
      final listingId = await service.shareForSale(record.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta udostępniona w systemie (ID: $listingId). Agent został powiadomiony.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAssignDialog(BuildContext context, ListingSubmissionRecord record) {
    final adminService = ref.read(_adminServiceProvider);
    final submissionService = ref.read(_submissionServiceProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => _AssignDialogContent(
        record: record,
        adminService: adminService,
        submissionService: submissionService,
        onAssigned: () => Navigator.of(ctx).pop(),
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

/// Dialog wyboru agenta i przypisania zgłoszenia.
class _AssignDialogContent extends StatefulWidget {
  final ListingSubmissionRecord record;
  final AdminService adminService;
  final ListingSubmissionService submissionService;
  final VoidCallback onAssigned;

  const _AssignDialogContent({
    required this.record,
    required this.adminService,
    required this.submissionService,
    required this.onAssigned,
  });

  @override
  State<_AssignDialogContent> createState() => _AssignDialogContentState();
}

class _AssignDialogContentState extends State<_AssignDialogContent> {
  List<AdminUserRecord>? _agents;
  String? _selectedAgentId;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    widget.adminService.getAgents().then((list) {
      if (mounted) {
        setState(() {
          _agents = list;
          _loading = false;
          if (list.isNotEmpty) _selectedAgentId = list.first.id;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Przypisz do Agenta'),
      content: _loading
          ? const SizedBox(
              width: 200,
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          : _error != null
              ? Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))
              : _agents == null || _agents!.isEmpty
                  ? const Text('Brak agentów w systemie. Dodaj użytkowników z rolą Agent w panelu Użytkownicy.')
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Zgłoszenie: ${widget.record.referenceNumber}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          value: _selectedAgentId,
                          decoration: const InputDecoration(
                            labelText: 'Agent',
                            border: OutlineInputBorder(),
                          ),
                          items: _agents!
                              .map((a) => DropdownMenuItem<String>(
                                    value: a.id,
                                    child: Text(a.displayName?.trim().isNotEmpty == true
                                        ? '${a.displayName} (${a.email ?? a.id})'
                                        : (a.email ?? a.id)),
                                  ))
                              .toList(),
                          onChanged: (id) => setState(() => _selectedAgentId = id),
                        ),
                      ],
                    ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        if (_agents != null && _agents!.isNotEmpty)
          FilledButton(
            onPressed: _submitting || _selectedAgentId == null
                ? null
                : () async {
                    setState(() => _submitting = true);
                    try {
                      await widget.submissionService.assignToAgent(
                        widget.record.id,
                        _selectedAgentId!,
                      );
                      if (mounted) {
                        widget.onAssigned();
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _submitting = false;
                          _error = e.toString();
                        });
                      }
                    }
                  },
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Przypisz'),
          ),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final ListingSubmissionRecord record;
  final String? assignedAgentName;
  final VoidCallback? onPreview;
  final VoidCallback? onAssign;
  final VoidCallback? onShareForSale;
  final VoidCallback onReject;
  final VoidCallback onContact;

  const _SubmissionCard({
    required this.record,
    this.assignedAgentName,
    this.onPreview,
    this.onAssign,
    this.onShareForSale,
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
            if (assignedAgentName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Przypisany do: $assignedAgentName',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(record.referenceNumber, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            Text('${record.typeShortLabel} – ${record.city ?? ''}${record.voivodeship != null ? ', ${record.voivodeship}' : ''}'),
            if (record.contactEmail != null) Text(record.contactEmail!),
            if (record.contactPhone != null) Text(record.contactPhone!),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onPreview != null)
                  TextButton(onPressed: onPreview, child: const Text('Podgląd')),
                if (onShareForSale != null)
                  TextButton(onPressed: onShareForSale, child: const Text('Udostępnij do sprzedaży'))
                else if (onAssign != null)
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
