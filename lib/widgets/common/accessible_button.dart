import 'package:flutter/material.dart';

/// Accessible button with proper semantics and keyboard navigation
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticLabel;
  final String? tooltip;
  final bool isPrimary;
  final bool isOutlined;
  
  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.semanticLabel,
    this.tooltip,
    this.isPrimary = true,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (isOutlined) {
      button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
      );
    } else if (isPrimary) {
      button = ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
      );
    } else {
      button = TextButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
      );
    }
    
    // Wrap with semantics for screen readers
    button = Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: button,
    );
    
    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    // Make focusable for keyboard navigation
    return Focus(
      onKey: (node, event) {
        if (event.logicalKey.keyLabel == 'Enter' || 
            event.logicalKey.keyLabel == ' ') {
          onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: button,
    );
  }
}

/// Accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: color,
    );
    
    // Wrap with semantics
    button = Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(child: button),
    );
    
    // Add tooltip
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    // Make focusable for keyboard navigation
    return Focus(
      onKey: (node, event) {
        if (event.logicalKey.keyLabel == 'Enter' || 
            event.logicalKey.keyLabel == ' ') {
          onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: button,
    );
  }
}

/// Accessible text input with proper labels
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? semanticLabel;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  
  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.semanticLabel,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}
