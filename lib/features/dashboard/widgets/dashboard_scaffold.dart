import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';
import '../../../widgets/navigation/sidebar.dart';

/// Wspólny layout dla podstron panelu użytkownika: AppBar z powrotem + tytuł,
/// drawer/sidebar, responsywny układ (mobile: drawer, desktop: stały sidebar).
class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.actions,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = MediaQuery.paddingOf(context);
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;
    final contentPadding = screenWidth < AppSpacing.mobileBreakpoint
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)
        : const EdgeInsets.all(AppSpacing.xl);

    return Scaffold(
      appBar: AppBarCustom(
        showBackButton: true,
        title: title,
        onBackPressed: () => context.go(AppRouter.dashboard),
        actions: actions,
      ),
      drawer: !isDesktop
          ? Sidebar(currentRoute: currentRoute)
          : null,
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 280,
              child: Sidebar(currentRoute: currentRoute),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                contentPadding.left + padding.left,
                contentPadding.top + padding.top,
                contentPadding.right + padding.right,
                contentPadding.bottom + padding.bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
