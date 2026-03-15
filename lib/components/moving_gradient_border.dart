import 'package:flutter/material.dart';
import 'package:haflaway/utils/gus_theme.dart';
import 'dart:math' as math;

class MovingGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color>? gradientColors;
  final Duration duration;

  const MovingGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.gradientColors,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<MovingGradientBorder> createState() => _MovingGradientBorderState();
}

class _MovingGradientBorderState extends State<MovingGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.gradientColors ??
        [
          GusTheme.gold,
          const Color(0xFF4A6CF7), // Brand Blue
          Colors.purpleAccent,
          GusTheme.gold,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            rotation: _controller.value * 2 * math.pi,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            colors: colors,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double rotation;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;

  _GradientBorderPainter({
    required this.rotation,
    required this.borderWidth,
    required this.borderRadius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final paint =
        Paint()
          ..shader = SweepGradient(
            colors: colors,
            transform: GradientRotation(rotation),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
