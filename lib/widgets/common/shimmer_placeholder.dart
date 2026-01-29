import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shimmer skeleton placeholder for image/content loading.
/// Uses animated gradient for a subtle loading effect.
class ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppSpacing.radiusMd),
            color: AppColors.grey200,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppSpacing.radiusMd),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : (widget.width ?? 200);
                final h = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : (widget.height ?? 200);
                return CustomPaint(
                  painter: _ShimmerPainter(progress: _animation.value),
                  size: Size(w, h),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const baseColor = AppColors.grey200;
    const highlightColor = Color(0xFFE8E8E8);
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + progress, 0),
      end: Alignment(1.0 + progress, 0),
      colors: [
        baseColor,
        highlightColor,
        Color.lerp(highlightColor, baseColor, 0.3)!,
        baseColor,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
    final rect = Offset.zero & size;
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
