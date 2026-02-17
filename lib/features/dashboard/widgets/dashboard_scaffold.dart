import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/navigation/app_bar_custom.dart';

/// Wspólny layout dla podstron panelu użytkownika: AppBar z powrotem + tytuł.
/// Sidebar jest zapewniany przez ShellRoute (ScaffoldWithSidebar).
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
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          contentPadding.left + padding.left,
          contentPadding.top + padding.top,
          contentPadding.right + padding.right,
          contentPadding.bottom + padding.bottom,
        ),
        child: child,
      ),
    );
  }
}
