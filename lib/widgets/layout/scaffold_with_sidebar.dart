import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/state/providers/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/mobile_menu.dart';
import '../navigation/sidebar_x.dart';

/// Udostępnia callback do otwarcia drawera z sidebarem (np. z AppBar).
class SidebarShellScope extends InheritedWidget {
  const SidebarShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static VoidCallback? maybeOpenDrawerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SidebarShellScope>()?.openDrawer;
  }

  @override
  bool updateShouldNotify(SidebarShellScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

/// Shell layout: na desktopie stały sidebar, na mobile/tablet drawer.
/// Używany przez ShellRoute – wszystkie widoki oprócz logowania.
class ScaffoldWithSidebar extends ConsumerStatefulWidget {
  const ScaffoldWithSidebar({
    super.key,
    required this.child,
    this.currentRoute,
  });

  final Widget child;
  final String? currentRoute;

  @override
  ConsumerState<ScaffoldWithSidebar> createState() => _ScaffoldWithSidebarState();
}

class _ScaffoldWithSidebarState extends ConsumerState<ScaffoldWithSidebar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCollapsed = false;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;

    final user = ref.watch(currentUserProvider).asData?.value;
    final roleLevel = user?.effectiveRoleLevel ?? UserRoleLevel.guest;
    final hasSidebar = roleLevel != UserRoleLevel.guest;

    if (isDesktop) {
      return SidebarShellScope(
        openDrawer: () {},
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSidebar)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: _isCollapsed ? 64 : 280,
                child: SidebarXShell(
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                  onToggleCollapsed: () => setState(() => _isCollapsed = !_isCollapsed),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return SidebarShellScope(
      openDrawer: _openDrawer,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: hasSidebar ? const MobileMenu() : null,
        body: widget.child,
      ),
    );
  }
}
