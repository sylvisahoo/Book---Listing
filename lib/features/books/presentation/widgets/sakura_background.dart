import 'dart:math' as math;
import 'package:flutter/material.dart';

class SakuraBackground extends StatelessWidget {
  final Widget child;

  const SakuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The cherry blossom background painter
        Positioned.fill(child: CustomPaint(painter: _SakuraPainter())),
        child,
      ],
    );
  }
}

class _SakuraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = const Color(0xFF6E5568)
          .withOpacity(0.15) // Soft woody brown-purple
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final petalPaintPrimary = Paint()
      ..color = const Color(0xFFF8BBD9)
          .withOpacity(0.4) // Soft pink
      ..style = PaintingStyle.fill;

    final petalPaintAccent = Paint()
      ..color = const Color(0xFFE78FB3)
          .withOpacity(0.35) // Deep rose pink
      ..style = PaintingStyle.fill;

    // 1. Draw a soft decorative branch in the top right corner
    final branchPath = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.1,
        size.width * 0.7,
        0,
      )
      ..moveTo(size.width * 0.85, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.15,
        size.width * 0.73,
        size.height * 0.18,
      );
    canvas.drawPath(branchPath, branchPaint);

    // 2. Draw flower blossoms on the branch
    _drawBlossom(
      canvas,
      Offset(size.width * 0.8, size.height * 0.08),
      8,
      petalPaintPrimary,
      petalPaintAccent,
    );
    _drawBlossom(
      canvas,
      Offset(size.width * 0.73, size.height * 0.18),
      6,
      petalPaintPrimary,
      petalPaintAccent,
    );
    _drawBlossom(
      canvas,
      Offset(size.width * 0.88, size.height * 0.04),
      7,
      petalPaintPrimary,
      petalPaintAccent,
    );

    // 3. Draw falling petals across the screen
    final random = math.Random(12345); // Seeded random to avoid flickering
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final scale = 4.0 + random.nextDouble() * 6.0;
      final rotation = random.nextDouble() * math.pi;

      _drawPetal(
        canvas,
        Offset(x, y),
        scale,
        rotation,
        i % 2 == 0 ? petalPaintPrimary : petalPaintAccent,
      );
    }
  }

  void _drawBlossom(
    Canvas canvas,
    Offset center,
    double size,
    Paint petalPaint,
    Paint centerPaint,
  ) {
    // Draw 5 petals around the center
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5;
      final petalOffset = Offset(
        center.dx + math.cos(angle) * size * 0.8,
        center.dy + math.sin(angle) * size * 0.8,
      );
      canvas.drawCircle(petalOffset, size * 0.7, petalPaint);
    }
    // Center of the flower
    canvas.drawCircle(center, size * 0.4, centerPaint);
  }

  void _drawPetal(
    Canvas canvas,
    Offset position,
    double size,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Drawing a simple teardrop petal shape
    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.6, -size * 0.5, size * 0.2, size)
      ..quadraticBezierTo(0, size * 1.2, -size * 0.2, size)
      ..quadraticBezierTo(-size * 0.6, -size * 0.5, 0, -size);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
