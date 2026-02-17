import 'package:flutter/foundation.dart';
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
import '../widgets/empty_state.dart';

final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Lista zgłoszeń "Chcę sprzedać" użytkownika (dodane oferty). Wejście z dashboardu, sidebara, menu.
class MySubmissionsPage extends ConsumerWidget {
  const MySubmissionsPage({super.key});

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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final uid = user?.id;
    if (uid == null || uid.isEmpty) {
      return DashboardScaffold(
        title: 'Moje zgłoszenia',
        currentRoute: AppRouter.dashboardMySubmissions,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zaloguj się, aby zobaczyć swoje zgłoszenia',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.go(AppRouter.logowanie),
                  child: const Text('Zaloguj się'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final service = ref.watch(_submissionServiceProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Moje zgłoszenia',
      currentRoute: AppRouter.dashboardMySubmissions,
      child: StreamBuilder<List<ListingSubmissionRecord>>(
        stream: service.streamSubmissionsByUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('[MySubmissionsPage] Firestore/stream error: ${snapshot.error}');
            if (snapshot.stackTrace != null) {
              debugPrint('[MySubmissionsPage] Stack trace: ${snapshot.stackTrace}');
            }
            return _buildError(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return DashboardEmptyState(
              title: 'Brak zgłoszeń',
              subtitle: 'Nie masz jeszcze zgłoszeń z formularza „Chcę sprzedać”.',
              icon: Icons.real_estate_agent_outlined,
            );
          }
          return isMobile
              ? _buildMobileList(context, list)
              : _buildDesktopList(context, list);
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<ListingSubmissionRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final r = list[index];
        return _SubmissionTile(
          record: r,
          onTap: () => context.push(AppRouter.dashboardMySubmissionDetail(r.id)),
        );
      },
    );
  }

  Widget _buildDesktopList(BuildContext context, List<ListingSubmissionRecord> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final r = list[index];
        return _SubmissionTile(
          record: r,
          onTap: () => context.push(AppRouter.dashboardMySubmissionDetail(r.id)),
        );
      },
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.record, required this.onTap});

  final ListingSubmissionRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = '${record.city ?? ''}${record.voivodeship != null ? ', ${record.voivodeship}' : ''}'.trim();
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.referenceNumber,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.typeShortLabel}${loc.isNotEmpty ? ' · $loc' : ''}',
                      style: AppTextStyles.titleSmall,
                    ),
                    if (record.expectedPrice != null && record.expectedPrice! > 0)
                      Text(
                        _formatPrice(record.expectedPrice!),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(record.statusLabel, style: AppTextStyles.labelSmall),
                backgroundColor: MySubmissionsPage._statusColor(record.status).withValues(alpha: 0.2),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} mln zł';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)} tys. zł';
    return '${v.toStringAsFixed(0)} zł';
  }
}
