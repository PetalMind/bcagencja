/// Application spacing system based on 4px base unit
class AppSpacing {
  // Base unit
  static const double base = 4.0;
  
  // Spacing values
  static const double xs = base; // 4px
  static const double sm = base * 2; // 8px
  static const double md = base * 4; // 16px
  static const double lg = base * 6; // 24px
  static const double xl = base * 8; // 32px
  static const double xxl = base * 12; // 48px
  static const double xxxl = base * 16; // 64px
  
  // Container constraints
  static const double containerMaxWidth = 1400.0;
  static const double containerMaxWidthNarrow = 1200.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  
  // Border radius
  static const double radiusXs = base; // 4px
  static const double radiusSm = base * 2; // 8px
  static const double radiusMd = base * 3; // 12px
  static const double radiusLg = base * 4; // 16px
  static const double radiusXl = base * 6; // 24px
  static const double radiusFull = 9999.0; // Full circle
  
  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  
  // Grid columns
  static const int gridColumnsMobile = 4;
  static const int gridColumnsTablet = 8;
  static const int gridColumnsDesktop = 12;
}
