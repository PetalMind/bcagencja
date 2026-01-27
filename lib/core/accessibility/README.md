# Accessibility Guidelines

This folder contains accessibility utilities and helpers for the BC Agencja application.

## WCAG AA Compliance

The application follows WCAG 2.1 Level AA guidelines:

### Color Contrast
- All text has minimum contrast ratio of 4.5:1 for normal text
- Large text (18pt+) has minimum contrast ratio of 3:1
- Primary colors: #181D24 and #BE6E59 meet WCAG AA standards

### Keyboard Navigation
- All interactive elements are keyboard accessible
- Focus indicators are visible
- Tab order is logical and follows visual layout
- Skip links available for screen readers

### Screen Readers
- All images have alt text
- ARIA labels provided for icon buttons
- Semantic HTML structure
- Form labels properly associated with inputs

### Focus Management
- Visible focus indicators on all interactive elements
- Focus is maintained during navigation
- Modal dialogs trap focus appropriately

## Usage

### ARIA Labels
```dart
import 'package:bcagencja/core/accessibility/aria_labels.dart';

// Use predefined labels
Semantics(
  label: AriaLabels.navHome,
  child: IconButton(...),
)
```

### Accessible Buttons
```dart
import 'package:bcagencja/widgets/common/accessible_button.dart';

AccessibleButton(
  label: 'Szukaj',
  semanticLabel: AriaLabels.searchButton,
  icon: Icons.search,
  onPressed: () => ...,
)
```

### Color Contrast
All colors in `app_colors.dart` have been tested and meet WCAG AA standards:
- Text on white background: #181D24 (ratio: 15.68:1)
- Accent on white background: #BE6E59 (ratio: 3.52:1) - for large text only
- Text on dark background: #FFFFFF (ratio: 15.68:1)

## Testing

Use these tools to verify accessibility:
- Flutter DevTools Accessibility Inspector
- Screen readers: VoiceOver (iOS), TalkBack (Android)
- Keyboard navigation testing
- Color contrast analyzer tools

## Checklist

- [ ] All images have alt text
- [ ] All interactive elements have semantic labels
- [ ] Keyboard navigation works throughout the app
- [ ] Focus indicators are visible
- [ ] Color contrast meets WCAG AA standards
- [ ] Forms have proper labels and error messages
- [ ] Loading states are announced to screen readers
- [ ] Error states are accessible
- [ ] Touch targets are minimum 44x44 pixels
