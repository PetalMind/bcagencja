import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  gradient,
}

enum ButtonSize {
  small,
  medium,
  large,
}

/// Modern, reusable button widget with geometric design elements
/// matching the hero section style
class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final String? tooltip;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _hoverController;
  late AnimationController _glowController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverSlideAnimation;
  late Animation<double> _borderGlowAnimation;
  late Animation<double> _geometricShiftAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Press animation - sharp compress effect
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
    
    // Hover animation - smooth geometric entrance
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _hoverSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    // Border glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _borderGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Geometric shift for depth
    _geometricShiftAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  void _onHoverEnter() {
    setState(() => _isHovered = true);
    _hoverController.forward();
    _glowController.repeat(reverse: true);
  }
  
  void _onHoverExit() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
    _glowController.stop();
    _glowController.reset();
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 18;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = widget.size == ButtonSize.small
        ? AppTextStyles.labelMedium
        : widget.size == ButtonSize.medium
            ? AppTextStyles.labelLarge
            : AppTextStyles.titleSmall;

    return baseStyle.copyWith(
      fontWeight: FontWeight.w300, // Light weight
      letterSpacing: 1.2, // Better spacing for uppercase
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: widget.onPressed != null ? (_) => _onHoverEnter() : null,
      onExit: widget.onPressed != null ? (_) => _onHoverExit() : null,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) => _pressController.forward() : null,
        onTapUp: widget.onPressed != null ? (_) {
          _pressController.reverse();
          // Trigger click ripple effect
          _triggerClickEffect();
        } : null,
        onTapCancel: widget.onPressed != null ? () => _pressController.reverse() : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: Listenable.merge([_hoverController, _glowController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_geometricShiftAnimation.value * 0.5),
                child: Container(
                  width: widget.fullWidth ? double.infinity : null,
                  child: _buildButton(),
                ),
              );
            },
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
  
  void _triggerClickEffect() {
    // Visual feedback for click
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  Widget _buildButton() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.outlined:
        return _buildOutlinedButton();
      case ButtonVariant.text:
        return _buildTextButton();
      case ButtonVariant.gradient:
        return _buildGradientButton();
    }
  }

  Widget _buildPrimaryButton() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated geometric slices from sides
            Positioned.fill(
              child: ClipRect(
                child: CustomPaint(
                  painter: _AnimatedGeometricPainter(
                    color: AppColors.accent,
                    progress: _hoverSlideAnimation.value,
                    glowProgress: _borderGlowAnimation.value,
                  ),
                ),
              ),
            ),
            
            // Hover border glow effect
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.accent.withOpacity(
                            0.3 + (_borderGlowAnimation.value * 0.4),
                          ),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Main button with slide-in background
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  padding: _getPadding(),
                  decoration: BoxDecoration(
                    color: widget.onPressed == null
                        ? AppColors.grey400
                        : AppColors.accent,
                  ),
                  child: _buildButtonContent(AppColors.white),
                ),
              ),
            ),
            
            // Enhanced shadow on hover
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 20 + (_geometricShiftAnimation.value * 2),
                          offset: Offset(0, 6 + _geometricShiftAnimation.value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryButton() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Stack(
          children: [
            // Subtle geometric accents
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _AnimatedGeometricPainter(
                    color: AppColors.white,
                    progress: _hoverSlideAnimation.value,
                    glowProgress: _borderGlowAnimation.value,
                  ),
                ),
              ),
            
            // Main button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  padding: _getPadding(),
                  decoration: BoxDecoration(
                    color: widget.onPressed == null
                        ? AppColors.grey200
                        : AppColors.primaryDark,
                  ),
                  child: _buildButtonContent(AppColors.white),
                ),
              ),
            ),
            
            // Enhanced shadow on hover
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.3),
                          blurRadius: 12 + (_geometricShiftAnimation.value),
                          offset: Offset(0, 4 + (_geometricShiftAnimation.value * 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOutlinedButton() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated border draw effect
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _BorderDrawPainter(
                    color: AppColors.accent,
                    progress: _hoverSlideAnimation.value,
                  ),
                ),
              ),
            
            // Main button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  padding: _getPadding(),
                  decoration: BoxDecoration(
                    color: _isHovered && widget.onPressed != null
                        ? AppColors.accent.withOpacity(
                            0.05 + (_hoverSlideAnimation.value * 0.05),
                          )
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.onPressed == null
                          ? AppColors.grey400
                          : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: _buildButtonContent(
                    widget.onPressed == null ? AppColors.grey400 : AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextButton() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Main button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLoading ? null : widget.onPressed,
                    child: Container(
                      padding: _getPadding(),
                      decoration: BoxDecoration(
                        color: _isHovered && widget.onPressed != null
                            ? AppColors.grey100.withOpacity(
                                _hoverSlideAnimation.value * 0.5,
                              )
                            : Colors.transparent,
                      ),
                      child: _buildButtonContent(
                        widget.onPressed == null
                            ? AppColors.grey400
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                
                // Underline slide-in effect
                if (_isHovered && widget.onPressed != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      widthFactor: _hoverSlideAnimation.value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        color: AppColors.accent.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGradientButton() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated geometric particles
            Positioned.fill(
              child: ClipRect(
                child: CustomPaint(
                  painter: _AnimatedGeometricPainter(
                    color: AppColors.accent,
                    progress: _hoverSlideAnimation.value,
                    glowProgress: _borderGlowAnimation.value,
                    isGradient: true,
                  ),
                ),
              ),
            ),
            
            // Pulsing border on hover
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.white.withOpacity(
                            0.2 + (_borderGlowAnimation.value * 0.3),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Gradient button with animated background shift
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  padding: _getPadding(),
                  decoration: BoxDecoration(
                    gradient: widget.onPressed == null
                        ? null
                        : LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.accent.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            transform: GradientRotation(
                              _hoverSlideAnimation.value * 0.2,
                            ),
                          ),
                    color: widget.onPressed == null ? AppColors.grey400 : null,
                  ),
                  child: _buildButtonContent(AppColors.white),
                ),
              ),
            ),
            
            // Premium glow effect
            if (_isHovered && widget.onPressed != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.5),
                          blurRadius: 24 + (_geometricShiftAnimation.value * 3),
                          offset: Offset(0, 8 + _geometricShiftAnimation.value),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final content = <Widget>[];

    if (widget.icon != null) {
      content.add(Icon(widget.icon, size: _getIconSize(), color: textColor));
      content.add(const SizedBox(width: AppSpacing.sm));
    }

    content.add(
      Text(
        widget.label.toUpperCase(), // Convert to uppercase
        style: _getTextStyle().copyWith(color: textColor),
      ),
    );

    if (widget.trailingIcon != null) {
      content.add(const SizedBox(width: AppSpacing.sm));
      content.add(Icon(
        widget.trailingIcon,
        size: _getIconSize(),
        color: textColor,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: content,
    );
  }
}

/// Animated geometric painter with slide-in effects
class _AnimatedGeometricPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double glowProgress;
  final bool isGradient;

  _AnimatedGeometricPainter({
    required this.color,
    required this.progress,
    required this.glowProgress,
    this.isGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    // Animated slices from left and right
    final leftPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.08 * progress);

    final rightPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.12 * progress);

    // Left slice - slides in from left
    final leftSliceWidth = size.width * 0.4 * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftSliceWidth, size.height),
      leftPaint,
    );

    // Right slice - slides in from right
    final rightSliceWidth = size.width * 0.35 * progress;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - rightSliceWidth,
        0,
        rightSliceWidth,
        size.height,
      ),
      rightPaint,
    );

    // Diagonal accent lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(0.15 * progress)
      ..strokeWidth = 1.5;

    // Animated diagonal from top-left
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width * 0.3 * progress, size.height),
      linePaint,
    );

    // Animated diagonal from bottom-right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(
        size.width - (size.width * 0.3 * progress),
        0,
      ),
      linePaint,
    );

    // Corner geometric accents
    final accentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.1 * progress);

    // Top-left corner triangle
    final topLeftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(30 * progress, 0)
      ..lineTo(0, 30 * progress)
      ..close();
    canvas.drawPath(topLeftPath, accentPaint);

    // Bottom-right corner triangle
    final bottomRightPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width - (30 * progress), size.height)
      ..lineTo(size.width, size.height - (30 * progress))
      ..close();
    canvas.drawPath(bottomRightPath, accentPaint);

    // Pulsing dots for gradient variant
    if (isGradient && progress > 0.5) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.2 * glowProgress);

      final dotRadius = 2.0 + (glowProgress * 1.5);
      
      // Draw a few geometric dots
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.3),
        dotRadius,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.7),
        dotRadius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AnimatedGeometricPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowProgress != glowProgress ||
        oldDelegate.color != color ||
        oldDelegate.isGradient != isGradient;
  }
}

/// Border draw animation painter
class _BorderDrawPainter extends CustomPainter {
  final Color color;
  final double progress;

  _BorderDrawPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 3;

    final totalPerimeter = (size.width + size.height) * 2;
    final drawLength = totalPerimeter * progress;

    final path = Path();
    var currentLength = 0.0;

    // Start from top-left, draw clockwise
    // Top edge
    if (drawLength > currentLength) {
      final topLength = size.width.clamp(0.0, drawLength - currentLength);
      path.moveTo(0, 0);
      path.lineTo(topLength, 0);
      currentLength += size.width;
    }

    // Right edge
    if (drawLength > currentLength) {
      final rightLength = size.height.clamp(0.0, drawLength - currentLength);
      if (path.getBounds().isEmpty) path.moveTo(size.width, 0);
      path.lineTo(size.width, rightLength);
      currentLength += size.height;
    }

    // Bottom edge
    if (drawLength > currentLength) {
      final bottomLength = size.width.clamp(0.0, drawLength - currentLength);
      if (path.getBounds().isEmpty) path.moveTo(size.width, size.height);
      path.lineTo(size.width - bottomLength, size.height);
      currentLength += size.width;
    }

    // Left edge
    if (drawLength > currentLength) {
      final leftLength = size.height.clamp(0.0, drawLength - currentLength);
      if (path.getBounds().isEmpty) path.moveTo(0, size.height);
      path.lineTo(0, size.height - leftLength);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BorderDrawPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
