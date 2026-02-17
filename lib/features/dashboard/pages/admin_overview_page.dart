import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/listing_submission_service.dart';
import '../../../core/router/app_router.dart';
import '../widgets/dashboard_scaffold.dart';

final _adminServiceProvider = Provider<AdminService>((ref) => AdminService());
final _submissionServiceProvider = Provider<ListingSubmissionService>((ref) => ListingSubmissionService());

/// Panel admina: przegląd całego systemu – KPI i szybkie linki do podstron.
class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(_adminServiceProvider);
    final submissionService = ref.watch(_submissionServiceProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;

    return DashboardScaffold(
      title: 'Przegląd całego systemu',
      currentRoute: AppRouter.dashboardAdminOverview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kluczowe wskaźniki i szybki dostęp do sekcji panelu administracyjnego.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isMobile)
            _buildMobileCards(context, ref, adminService, submissionService)
          else
            _buildDesktopGrid(context, ref, adminService, submissionService),
          const SizedBox(height: AppSpacing.xl),
          _buildQuickLinks(context),
        ],
      ),
    );
  }

  Widget _buildMobileCards(
    BuildContext context,
    WidgetRef ref,
    AdminService adminService,
    ListingSubmissionService submissionService,
  ) {
    return Column(
      children: [
        StreamBuilder<List<AdminUserRecord>>(
          stream: adminService.streamUsers(),
          builder: (context, snapshot) => _OverviewCard(
            title: 'Użytkownicy',
            value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
            subtitle: 'Zarejestrowani w systemie',
            icon: Icons.people_outline,
            loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
            onTap: () => context.push(AppRouter.dashboardAdminUsers),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<ListingSubmissionRecord>>(
          stream: submissionService.streamSubmissions(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            final pending = list.where((r) => r.status == 'pending').length;
            return _OverviewCard(
              title: 'Zgłoszenia „Chcę sprzedać”',
              value: snapshot.hasData ? '${list.length}' : '—',
              subtitle: '$pending oczekujących',
              icon: Icons.real_estate_agent_outlined,
              loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
              onTap: () => context.push(AppRouter.dashboardAdminSubmissions),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<AdminLogRecord>>(
          stream: adminService.streamDocumentDownloads(limit: 100),
          builder: (context, snapshot) => _OverviewCard(
            title: 'Logi pobrań (VDR)',
            value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
            subtitle: 'Ostatnie 100 wpisów',
            icon: Icons.history,
            loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
            onTap: () => context.push(AppRouter.dashboardAdminLogs),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    WidgetRef ref,
    AdminService adminService,
    ListingSubmissionService submissionService,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: [
            StreamBuilder<List<AdminUserRecord>>(
              stream: adminService.streamUsers(),
              builder: (context, snapshot) => _OverviewCard(
                title: 'Użytkownicy',
                value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
                subtitle: 'Zarejestrowani w systemie',
                icon: Icons.people_outline,
                loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
                onTap: () => context.push(AppRouter.dashboardAdminUsers),
              ),
            ),
            StreamBuilder<List<ListingSubmissionRecord>>(
              stream: submissionService.streamSubmissions(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                final pending = list.where((r) => r.status == 'pending').length;
                return _OverviewCard(
                  title: 'Zgłoszenia „Chcę sprzedać”',
                  value: snapshot.hasData ? '${list.length}' : '—',
                  subtitle: '$pending oczekujących',
                  icon: Icons.real_estate_agent_outlined,
                  loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
                  onTap: () => context.push(AppRouter.dashboardAdminSubmissions),
                );
              },
            ),
            StreamBuilder<List<AdminLogRecord>>(
              stream: adminService.streamDocumentDownloads(limit: 100),
              builder: (context, snapshot) => _OverviewCard(
                title: 'Logi pobrań (VDR)',
                value: snapshot.hasData ? '${snapshot.data!.length}' : '—',
                subtitle: 'Ostatnie 100 wpisów',
                icon: Icons.history,
                loading: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData,
                onTap: () => context.push(AppRouter.dashboardAdminLogs),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szybkie linki',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickLinkChip(
                label: 'Użytkownicy',
                onTap: () => context.push(AppRouter.dashboardAdminUsers),
              ),
              _QuickLinkChip(
                label: 'Zgłoszenia „Chcę sprzedać”',
                onTap: () => context.push(AppRouter.dashboardAdminSubmissions),
              ),
              _QuickLinkChip(
                label: 'Logi systemowe',
                onTap: () => context.push(AppRouter.dashboardAdminLogs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                )
              else
                Text(
                  value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  const _QuickLinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.arrow_forward, size: 18, color: AppColors.accent),
    );
  }
}
