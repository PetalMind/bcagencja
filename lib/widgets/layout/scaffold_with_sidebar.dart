import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/sidebar.dart';

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
class ScaffoldWithSidebar extends StatefulWidget {
  const ScaffoldWithSidebar({
    super.key,
    required this.child,
    this.currentRoute,
  });

  final Widget child;
  final String? currentRoute;

  @override
  State<ScaffoldWithSidebar> createState() => _ScaffoldWithSidebarState();
}

class _ScaffoldWithSidebarState extends State<ScaffoldWithSidebar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= AppSpacing.tabletBreakpoint;

    if (isDesktop) {
      return SidebarShellScope(
        openDrawer: () {}, // desktop: sidebar zawsze widoczny, brak drawera
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: Sidebar(currentRoute: widget.currentRoute, keyPrefix: 'body'),
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
        drawer: Sidebar(currentRoute: widget.currentRoute, keyPrefix: 'drawer'),
        body: widget.child,
      ),
    );
  }
}
