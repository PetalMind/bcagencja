import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum ShimmerVariant {
  metallic,      // Metallic shine sweep
  holographic,   // Rainbow holographic effect
  premium,       // Subtle gold shimmer
  neon,          // Neon glow effect
}

/// Premium button with shimmer/shine effects
/// Perfect for luxury commercial real estate CTAs
class ShimmerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ShimmerVariant variant;
  final bool fullWidth;
  final bool autoAnimate;

  const ShimmerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = ShimmerVariant.metallic,
    this.fullWidth = false,
    this.autoAnimate = true,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _hoverController;
  late AnimationController _pressController;
  
  late Animation<double> _shimmerAnimation;
  late Animation<double> _hoverScale;
  late Animation<double> _pressScale;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Shimmer sweep animation
    _shimmerController = AnimationController(
      duration: Duration(milliseconds: widget.variant == ShimmerVariant.neon ? 1500 : 2000),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    // Hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _hoverScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOut,
      ),
    );
    
    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Auto-animate shimmer
    if (widget.autoAnimate) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _isHovered = true);
    _hoverController.forward();
    if (!widget.autoAnimate) {
      _shimmerController.repeat();
    }
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
    if (!widget.autoAnimate) {
      _shimmerController.stop();
      _shimmerController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.onPressed != null ? (_) => _onHoverEnter() : null,
      onExit: widget.onPressed != null ? (_) => _onHoverExit() : null,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) => _pressController.forward() : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                _pressController.reverse();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: widget.onPressed != null ? () => _pressController.reverse() : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_hoverController, _pressController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverScale.value * _pressScale.value,
              child: Container(
                width: widget.fullWidth ? double.infinity : null,
                child: _buildButton(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Stack(
      children: [
        // Base button
        _buildBaseButton(),
        
        // Shimmer overlay
        Positioned.fill(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ShimmerPainter(
                    progress: _shimmerAnimation.value,
                    variant: widget.variant,
                    isHovered: _isHovered,
                  ),
                );
              },
            ),
          ),
        ),
        
        // Content
        Positioned.fill(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildBaseButton() {
    Color? baseColor;
    Gradient? gradient;
    
    switch (widget.variant) {
      case ShimmerVariant.metallic:
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
            Color(0xFF2C3E50),
          ],
        );
        break;
      case ShimmerVariant.holographic:
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.accent,
            AppColors.primaryDark,
          ],
        );
        break;
      case ShimmerVariant.premium:
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B7355),
            Color(0xFFD4AF37),
            Color(0xFF8B7355),
          ],
        );
        break;
      case ShimmerVariant.neon:
        baseColor = AppColors.accent;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: baseColor,
        gradient: gradient,
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: _getGlowColor().withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: _getGlowColor().withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 24),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            widget.label.toUpperCase(),
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(widget.trailingIcon, color: Colors.white, size: 24),
          ],
        ],
      ),
    );
  }

  Color _getGlowColor() {
    switch (widget.variant) {
      case ShimmerVariant.metallic:
        return Colors.white;
      case ShimmerVariant.holographic:
        return AppColors.accent;
      case ShimmerVariant.premium:
        return const Color(0xFFFFD700);
      case ShimmerVariant.neon:
        return AppColors.accent;
    }
  }
}

/// Custom painter for shimmer effects
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final ShimmerVariant variant;
  final bool isHovered;

  _ShimmerPainter({
    required this.progress,
    required this.variant,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case ShimmerVariant.metallic:
        _paintMetallicShimmer(canvas, size);
        break;
      case ShimmerVariant.holographic:
        _paintHolographicShimmer(canvas, size);
        break;
      case ShimmerVariant.premium:
        _paintPremiumShimmer(canvas, size);
        break;
      case ShimmerVariant.neon:
        _paintNeonShimmer(canvas, size);
        break;
    }
  }

  void _paintMetallicShimmer(Canvas canvas, Size size) {
    // Metallic shine sweep - diagonal gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 0.5, -1),
      end: Alignment(progress + 0.5, 1),
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(isHovered ? 0.4 : 0.3),
        Colors.white.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintHolographicShimmer(Canvas canvas, Size size) {
    // Rainbow holographic effect
    final double centerX = size.width * progress;
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 0.3, -1),
      end: Alignment(progress + 0.3, 1),
      colors: [
        Colors.transparent,
        Colors.purple.withOpacity(0.2),
        Colors.blue.withOpacity(0.2),
        Colors.cyan.withOpacity(0.3),
        Colors.green.withOpacity(0.2),
        Colors.yellow.withOpacity(0.2),
        Colors.transparent,
      ],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Add sparkle dots
    if (progress > 0.3 && progress < 0.7) {
      final sparkle = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(
        Offset(centerX, size.height * 0.3),
        3,
        sparkle,
      );
      canvas.drawCircle(
        Offset(centerX + 20, size.height * 0.7),
        2,
        sparkle,
      );
    }
  }

  void _paintPremiumShimmer(Canvas canvas, Size size) {
    // Gold/bronze shimmer effect
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(progress - 0.4, -1),
      end: Alignment(progress + 0.4, 1),
      colors: [
        Colors.transparent,
        const Color(0xFFFFD700).withOpacity(0.1),
        const Color(0xFFFFD700).withOpacity(0.3),
        const Color(0xFFFFF8DC).withOpacity(0.4),
        const Color(0xFFFFD700).withOpacity(0.3),
        const Color(0xFFFFD700).withOpacity(0.1),
        Colors.transparent,
      ],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintNeonShimmer(Canvas canvas, Size size) {
    // Neon glow pulse
    final double intensity = (progress % 1.0);
    
    // Outer glow
    final outerPaint = Paint()
      ..color = const Color(0xFFBE6E59).withOpacity(0.2 + (intensity * 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawRect(
      Rect.fromLTWH(-10, -10, size.width + 20, size.height + 20),
      outerPaint,
    );
    
    // Inner shine line
    if (progress > -0.5 && progress < 1.5) {
      final lineX = size.width * progress;
      final linePaint = Paint()
        ..shader = LinearGradient(
          begin: const Alignment(0, -1),
          end: const Alignment(0, 1),
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.6),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(lineX - 2, 0, 4, size.height))
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawLine(
        Offset(lineX, 0),
        Offset(lineX, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isHovered != isHovered;
  }
}
