import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/listing_submission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/state/providers/auth_provider.dart';
import '../widgets/dashboard_scaffold.dart';

final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Widok szczegółów jednego zgłoszenia użytkownika (tylko własne).
class MySubmissionDetailPage extends ConsumerWidget {
  const MySubmissionDetailPage({super.key, required this.submissionId});

  final String submissionId;

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'contracted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.grey600;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final uid = user?.id;
    final service = ref.watch(_submissionServiceProvider);

    if (uid == null || uid.isEmpty) {
      return DashboardScaffold(
        title: 'Szczegóły zgłoszenia',
        currentRoute: AppRouter.dashboardMySubmissionDetail(submissionId),
        child: const Center(child: Text('Zaloguj się, aby zobaczyć zgłoszenie.')),
      );
    }

    return DashboardScaffold(
      title: 'Szczegóły zgłoszenia',
      currentRoute: AppRouter.dashboardMySubmissionDetail(submissionId),
      child: FutureBuilder<ListingSubmissionRecord?>(
        future: service.getSubmission(submissionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }
          final record = snapshot.data;
          if (record == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nie znaleziono zgłoszenia',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go(AppRouter.dashboardMySubmissions),
                      child: const Text('Wróć do listy'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (record.submittedByUid != null && record.submittedByUid != uid) {
            return const Center(child: Text('Brak dostępu do tego zgłoszenia.'));
          }
          return SingleChildScrollView(
            child: _DetailContent(record: record),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.record});

  final ListingSubmissionRecord record;

  static String _formatPrice(double? v) {
    if (v == null || v <= 0) return '—';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} mln zł';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} tys. zł';
    return '${v.toStringAsFixed(0)} zł';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              record.referenceNumber,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Chip(
              label: Text(record.statusLabel, style: AppTextStyles.labelSmall),
              backgroundColor: MySubmissionDetailPage._statusColor(record.status).withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: 'Typ i lokalizacja', children: [
          _Row(label: 'Typ', value: record.typeDisplayLabel),
          if (record.displayAddress != null && record.displayAddress!.isNotEmpty)
            _Row(label: 'Adres', value: record.displayAddress!),
          _Row(label: 'Miejscowość', value: record.locality ?? record.city ?? '—'),
          _Row(label: 'Województwo', value: record.voivodeship ?? '—'),
        ]),
        _Section(title: 'Dane', children: [
          if (record.area != null && record.area! > 0)
            _Row(label: 'Powierzchnia', value: '${record.area!.toStringAsFixed(0)} m²'),
          if (record.tenants.isNotEmpty) ...[
            _Row(
              label: record.tenants.length == 1 ? 'Najemca' : 'Najemcy',
              value: record.tenants.map((t) {
                final parts = <String>[t.name];
                if (t.monthlyRent != null && t.monthlyRent! > 0) {
                  parts.add('${t.monthlyRent!.toStringAsFixed(0)} zł/mies.');
                }
                if (t.leaseUntil != null) {
                  parts.add('umowa do ${MySubmissionDetailPage._formatDate(t.leaseUntil)}');
                }
                return parts.join(' · ');
              }).join('\n'),
            ),
            if (record.monthlyRent != null && record.monthlyRent! > 0 && record.tenants.length > 1)
              _Row(label: 'Łączny czynsz miesięczny', value: '${record.monthlyRent!.toStringAsFixed(0)} zł'),
          ],
          if (record.mpzp != null && record.mpzp!.isNotEmpty)
            _Row(label: 'MPZP', value: record.mpzp!),
        ]),
        _Section(title: 'Cena', children: [
          _Row(label: 'Oczekiwana cena', value: _formatPrice(record.expectedPrice)),
          if (record.estimatedValueMin != null || record.estimatedValueMax != null)
            _Row(
              label: 'Przedział',
              value: '${_formatPrice(record.estimatedValueMin)} – ${_formatPrice(record.estimatedValueMax)}',
            ),
          if (record.priceFlexibility != null && record.priceFlexibility!.isNotEmpty)
            _Row(label: 'Elastyczność', value: record.priceFlexibility!),
        ]),
        _Section(title: 'Kontakt', children: [
          _Row(label: 'Imię i nazwisko', value: record.contactName ?? '—'),
          _Row(label: 'E-mail', value: record.contactEmail ?? '—'),
          _Row(label: 'Telefon', value: record.contactPhone ?? '—'),
        ]),
        if (record.description != null && record.description!.isNotEmpty)
          _Section(title: 'Opis', children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                record.description!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ]),
        _Section(title: 'Status', children: [
          _Row(label: 'Data zgłoszenia', value: MySubmissionDetailPage._formatDate(record.createdAt)),
          if (record.rejectionReason != null && record.rejectionReason!.isNotEmpty)
            _Row(label: 'Powód odrzucenia', value: record.rejectionReason!),
        ]),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRouter.dashboardMySubmissions),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Wróć do listy'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
