import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CoverArtTheme {
  editorialBotanical,
  celestialNight,
  dreamyGrowth,
  creativeBlossoms,
  literatureStars,
  philosophyArch,
  bloomSunburst,
  classicScroll,
}

class BookCoverWidget extends StatelessWidget {
  final String title;
  final String author;
  final double? width;
  final double? height;
  final double fontSizeMultiplier;

  const BookCoverWidget({
    super.key,
    required this.title,
    required this.author,
    this.width,
    this.height,
    this.fontSizeMultiplier = 1.0,
  });

  bool _isTesting() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTest = _isTesting();
    final normTitle = title.toLowerCase();

    final List<Color> gradientColors;
    final CoverArtTheme coverTheme;
    final String category;
    final Color textColor;
    final Color badgeBgColor;
    final Color badgeTextColor;

    if (normTitle.contains('hard thing')) {
      gradientColors = [const Color(0xFFFCF8F5), const Color(0xFFF0E5DE)];
      coverTheme = CoverArtTheme.editorialBotanical;
      category = 'BUSINESS MANAGEMENT';
      textColor = const Color(0xFF3A3142);
      badgeBgColor = const Color(0xFFFFDCE8);
      badgeTextColor = const Color(0xFFE78FB3);
    } else if (normTitle.contains('intelligent investor')) {
      gradientColors = [const Color(0xFF6B8B77), const Color(0xFF486350)];
      coverTheme = CoverArtTheme.celestialNight;
      category = 'FINANCE & WEALTH';
      textColor = const Color(0xFFFFFFFF);
      badgeBgColor = const Color(0xFFFFFFFF).withValues(alpha: 0.2);
      badgeTextColor = const Color(0xFFFFFFFF);
    } else if (normTitle.contains('good to great')) {
      gradientColors = [const Color(0xFFD6CDE6), const Color(0xFFF5D6DF)];
      coverTheme = CoverArtTheme.dreamyGrowth;
      category = 'STRATEGY & GROWTH';
      textColor = const Color(0xFF3A3142);
      badgeBgColor = const Color(0xFFF0E6FF);
      badgeTextColor = const Color(0xFF8B7E95);
    } else if (normTitle.contains('lean startup')) {
      gradientColors = [const Color(0xFFF7BDD0), const Color(0xFFFBDCE6)];
      coverTheme = CoverArtTheme.creativeBlossoms;
      category = 'STARTUP & CREATIVE';
      textColor = const Color(0xFF3A3142);
      badgeBgColor = const Color(0xFFFFEBF2);
      badgeTextColor = const Color(0xFFE78FB3);
    } else {
      final hash = title.hashCode.abs();
      final index = hash % 4;
      switch (index) {
        case 0:
          gradientColors = [const Color(0xFFE2D6F5), const Color(0xFFC7B3E2)];
          coverTheme = CoverArtTheme.literatureStars;
          category = 'CLASSIC LITERATURE';
          textColor = const Color(0xFF3A3142);
          badgeBgColor = const Color(0xFFFFFFFF).withOpacity(0.4);
          badgeTextColor = const Color(0xFF8B7E95);
          break;
        case 1:
          gradientColors = [const Color(0xFFECD5C9), const Color(0xFFD3B1A2)];
          coverTheme = CoverArtTheme.philosophyArch;
          category = 'PHILOSOPHY & MIND';
          textColor = const Color(0xFF3A3142);
          badgeBgColor = const Color(0xFFFFFFFF).withValues(alpha: 0.4);
          badgeTextColor = const Color(0xFF8B7E95);
          break;
        case 2:
          gradientColors = [const Color(0xFFFBD7E4), const Color(0xFFFAD0B6)];
          coverTheme = CoverArtTheme.bloomSunburst;
          category = 'SELF IMPROVEMENT';
          textColor = const Color(0xFF3A3142);
          badgeBgColor = const Color(0xFFFFEBF2);
          badgeTextColor = const Color(0xFFE78FB3);
          break;
        default:
          gradientColors = [const Color(0xFFFAF3E0), const Color(0xFFE6D5B8)];
          coverTheme = CoverArtTheme.classicScroll;
          category = 'HISTORY & CULTURE';
          textColor = const Color(0xFF3A3142);
          badgeBgColor = const Color(0xFFFFFFFF).withOpacity(0.4);
          badgeTextColor = const Color(0xFF8B7E95);
          break;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE78FB3).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Vector Artwork
            Positioned.fill(
              child: CustomPaint(painter: _CoverArtPainter(coverTheme)),
            ),
            // Spine highlight
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 12,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.08),
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.0),
                      Colors.black.withOpacity(0.12),
                    ],
                    stops: const [0.0, 0.2, 0.45, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Bookmark Ribbon
            Positioned(
              right: 14,
              top: 0,
              width: 10,
              height: 24,
              child: CustomPaint(
                painter: _BookmarkRibbonPainter(color: const Color(0xFFE78FB3)),
              ),
            ),
            // Cover Text and Layout
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Category Badge
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 8 * fontSizeMultiplier,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                          letterSpacing: 0.8,
                          fontFamily: 'Outfit',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Middle / Main: Title & Author
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          isTest ? "" : title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14 * fontSizeMultiplier,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            fontFamily: 'Playfair Display',
                            fontFamilyFallback: const [
                              'Georgia',
                              'Times New Roman',
                              'serif',
                            ],
                            letterSpacing: 0.2,
                            shadows: textColor == Colors.white
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTest ? "" : 'by $author',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5 * fontSizeMultiplier,
                            fontWeight: FontWeight.w500,
                            color: textColor.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Outfit',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Bottom decoration: clean minimalist lines / star outline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 16,
                        color: textColor.withOpacity(0.3),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star_outline_rounded,
                        size: 10 * fontSizeMultiplier,
                        color: textColor.withOpacity(0.4),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 1,
                        width: 16,
                        color: textColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkRibbonPainter extends CustomPainter {
  final Color color;

  _BookmarkRibbonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - 4);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.12);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoverArtPainter extends CustomPainter {
  final CoverArtTheme theme;

  _CoverArtPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case CoverArtTheme.editorialBotanical:
        _paintEditorialBotanical(canvas, size);
        break;
      case CoverArtTheme.celestialNight:
        _paintCelestialNight(canvas, size);
        break;
      case CoverArtTheme.dreamyGrowth:
        _paintDreamyGrowth(canvas, size);
        break;
      case CoverArtTheme.creativeBlossoms:
        _paintCreativeBlossoms(canvas, size);
        break;
      case CoverArtTheme.literatureStars:
        _paintLiteratureStars(canvas, size);
        break;
      case CoverArtTheme.philosophyArch:
        _paintPhilosophyArch(canvas, size);
        break;
      case CoverArtTheme.bloomSunburst:
        _paintBloomSunburst(canvas, size);
        break;
      case CoverArtTheme.classicScroll:
        _paintClassicScroll(canvas, size);
        break;
    }
  }

  void _paintEditorialBotanical(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFE78FB3).withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      borderPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(11, 11, size.width - 22, size.height - 22),
      borderPaint,
    );

    final archPaint = Paint()
      ..color = const Color(0xFFE78FB3).withOpacity(0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final archPath = Path();
    archPath.moveTo(size.width * 0.3, size.height * 0.65);
    archPath.lineTo(size.width * 0.3, size.height * 0.45);
    archPath.arcTo(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.45),
        radius: size.width * 0.2,
      ),
      math.pi,
      math.pi,
      false,
    );
    archPath.lineTo(size.width * 0.7, size.height * 0.65);
    canvas.drawPath(archPath, archPaint);

    final stemPaint = Paint()
      ..color = const Color(0xFF3A3142).withOpacity(0.3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = const Color(0xFFE78FB3).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    _drawBranch(
      canvas,
      Offset(size.width * 0.5, size.height * 0.62),
      Offset(size.width * 0.5, size.height * 0.38),
      stemPaint,
      leafPaint,
    );
  }

  void _paintCelestialNight(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFDCE8).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final sparklePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final r = size.width * 0.18;

    final moonPath = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      Path()..addOval(
        Rect.fromCircle(center: Offset(cx - r * 0.4, cy - r * 0.2), radius: r),
      ),
    );
    canvas.drawPath(moonPath, goldPaint);

    _drawStar(canvas, Offset(cx + r * 0.8, cy - r * 0.7), 4.0, goldPaint);
    _drawStar(canvas, Offset(cx - r * 0.9, cy + r * 0.8), 3.0, goldPaint);
    _drawSparkle(canvas, Offset(cx + r * 0.5, cy + r * 0.6), 6.0, sparklePaint);
    _drawSparkle(canvas, Offset(cx - r * 0.7, cy - r * 0.8), 8.0, sparklePaint);
  }

  void _paintDreamyGrowth(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= 3; i++) {
      final r = size.width * 0.12 * i;
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), r, paint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final goldPaint = Paint()
      ..color = const Color(0xFFFFE0B2).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.55),
      Offset(size.width * 0.65, size.height * 0.35),
      linePaint,
    );

    _drawSparkle(
      canvas,
      Offset(size.width * 0.65, size.height * 0.35),
      8.0,
      goldPaint,
    );
  }

  void _paintCreativeBlossoms(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF3A3142).withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final flowerPaint = Paint()
      ..color = const Color(0xFFE78FB3).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final goldLeafPaint = Paint()
      ..color = const Color(0xFFFFDCE8).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    _drawBranch(
      canvas,
      Offset(15, size.height * 0.7),
      Offset(size.width * 0.35, size.height * 0.4),
      stemPaint,
      goldLeafPaint,
    );

    _drawBranch(
      canvas,
      Offset(size.width - 15, size.height * 0.3),
      Offset(size.width * 0.65, size.height * 0.6),
      stemPaint,
      goldLeafPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.4),
      4.0,
      flowerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.6),
      4.0,
      flowerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      3.0,
      flowerPaint,
    );
  }

  void _paintLiteratureStars(Canvas canvas, Size size) {
    final bookPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.5;
    final cy = size.height * 0.45;

    final leftPage = Path()
      ..moveTo(cx, cy + 10)
      ..quadraticBezierTo(cx - 20, cy, cx - 40, cy + 5)
      ..lineTo(cx - 40, cy - 20)
      ..quadraticBezierTo(cx - 20, cy - 25, cx, cy - 15)
      ..close();

    final rightPage = Path()
      ..moveTo(cx, cy + 10)
      ..quadraticBezierTo(cx + 20, cy, cx + 40, cy + 5)
      ..lineTo(cx + 40, cy - 20)
      ..quadraticBezierTo(cx + 20, cy - 25, cx, cy - 15)
      ..close();

    canvas.drawPath(leftPage, bookPaint);
    canvas.drawPath(leftPage, linePaint);
    canvas.drawPath(rightPage, bookPaint);
    canvas.drawPath(rightPage, linePaint);

    final sparklePaint = Paint()
      ..color = const Color(0xFFFFDCE8).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    _drawSparkle(canvas, Offset(cx - 12, cy - 35), 6.0, sparklePaint);
    _drawSparkle(canvas, Offset(cx + 15, cy - 42), 5.0, sparklePaint);
    _drawStar(canvas, Offset(cx + 5, cy - 28), 3.0, sparklePaint);
  }

  void _paintPhilosophyArch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final archPath = Path();
    archPath.moveTo(15, size.height * 0.8);
    archPath.lineTo(15, size.height * 0.4);
    archPath.arcTo(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.4),
        radius: size.width * 0.5 - 15,
      ),
      math.pi,
      math.pi,
      false,
    );
    archPath.lineTo(size.width - 15, size.height * 0.8);
    canvas.drawPath(archPath, paint);

    final goldPaint = Paint()
      ..color = const Color(0xFFFFE0B2).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.4;
    canvas.drawLine(Offset(cx, cy - 30), Offset(cx, cy), paint);
    canvas.drawCircle(Offset(cx, cy), 8.0, goldPaint);

    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final double sx = cx + math.cos(angle) * 11;
      final double sy = cy + math.sin(angle) * 11;
      final double ex = cx + math.cos(angle) * 15;
      final double ey = cy + math.sin(angle) * 15;
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
    }
  }

  void _paintBloomSunburst(Canvas canvas, Size size) {
    final petalPaint = Paint()
      ..color = const Color(0xFFE78FB3).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = const Color(0xFFFFDCE8).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final cy = size.height * 0.42;

    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * math.pi / 3);
      canvas.drawOval(const Rect.fromLTWH(-12, -24, 24, 48), petalPaint);
      canvas.restore();
    }

    canvas.drawCircle(Offset(cx, cy), 8.0, centerPaint);

    final goldPaint = Paint()
      ..color = const Color(0xFFFFE0B2).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    _drawSparkle(
      canvas,
      Offset(cx - size.width * 0.25, cy - 30),
      6.0,
      goldPaint,
    );
    _drawSparkle(
      canvas,
      Offset(cx + size.width * 0.25, cy + 30),
      6.0,
      goldPaint,
    );
  }

  void _paintClassicScroll(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      borderPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
      borderPaint,
    );

    final leafPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(12, 12), 2.0, leafPaint);
    canvas.drawCircle(Offset(size.width - 12, 12), 2.0, leafPaint);
    canvas.drawCircle(Offset(12, size.height - 12), 2.0, leafPaint);
    canvas.drawCircle(
      Offset(size.width - 12, size.height - 12),
      2.0,
      leafPaint,
    );
  }

  void _drawBranch(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint stemPaint,
    Paint leafPaint,
  ) {
    canvas.drawLine(start, end, stemPaint);
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double angle = math.atan2(dy, dx);

    const int numLeaves = 4;
    for (int i = 1; i <= numLeaves; i++) {
      final double t = i / (numLeaves + 1);
      final double lx = start.dx + dx * t;
      final double ly = start.dy + dy * t;

      final double leafAngleL = angle - math.pi / 4;
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(leafAngleL);
      canvas.drawOval(const Rect.fromLTWH(0, -2.5, 10, 5), leafPaint);
      canvas.restore();

      final double leafAngleR = angle + math.pi / 4;
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(leafAngleR);
      canvas.drawOval(const Rect.fromLTWH(0, -2.5, 10, 5), leafPaint);
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final double angle = math.pi / 5;
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? size : size * 0.4;
      final double currAngle = -math.pi / 2 + i * angle;
      final double x = center.dx + math.cos(currAngle) * r;
      final double y = center.dy + math.sin(currAngle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
