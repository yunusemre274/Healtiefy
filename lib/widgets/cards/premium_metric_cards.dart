import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// Premium Distance Card with turquoise gradient and ruler overlay
class PremiumDistanceCard extends StatelessWidget {
  final double distance;
  final String unit;
  final int animationDelay;

  const PremiumDistanceCard({
    super.key,
    required this.distance,
    this.unit = 'km',
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use aspect ratio to avoid overflow
        return AspectRatio(
          aspectRatio: 1.1, // Slightly wider than tall
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D5BFF), // Deep blue
                  Color(0xFF37F8DF), // Bright turquoise
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5BFF).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Ruler overlay background
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: _buildRulerOverlay(),
                  ),
                  // Inner glow effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.straighten_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        // Value and label
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                distance.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 3, bottom: 4),
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Distance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildRulerOverlay() {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _RulerPainter(),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw ruler marks
    for (int i = 0; i < 10; i++) {
      final y = size.height * (i / 10);
      final markLength = i % 5 == 0 ? 30.0 : 15.0;
      canvas.drawLine(
        Offset(size.width - markLength, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw vertical line
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium Calories Card with fire/yellow/orange gradient and flame overlay
class PremiumCaloriesCard extends StatelessWidget {
  final int calories;
  final int animationDelay;

  const PremiumCaloriesCard({
    super.key,
    required this.calories,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AspectRatio(
          aspectRatio: 1.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE600), // Bright yellow
                  Color(0xFFFF7A00), // Orange
                  Color(0xFFFF3B30), // Red
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Flame overlay background
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: _buildFlameOverlay(),
                  ),
                  // Inner glow effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        // Value and label
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$calories',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 3, bottom: 4),
                                child: Text(
                                  'kcal',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Calories',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildFlameOverlay() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _FlamePainter(),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw a simplified flame shape
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.7,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.7,
      size.width * 0.3,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.1,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium Active Time Card with purple gradient and clock overlay
class PremiumActiveTimeCard extends StatelessWidget {
  final int minutes;
  final int animationDelay;

  const PremiumActiveTimeCard({
    super.key,
    required this.minutes,
    this.animationDelay = 0,
  });

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AspectRatio(
          aspectRatio: 1.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB620FF), // Vibrant purple
                  Color(0xFFFF5DE6), // Pinkish purple
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB620FF).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Clock overlay background
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: _buildClockOverlay(),
                  ),
                  // Inner glow effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        // Value and label
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _formatTime(minutes),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Text(
                          'Active Time',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildClockOverlay() {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: _ClockPainter(),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw clock circle
    canvas.drawCircle(center, radius - 5, paint);

    // Draw hour marks
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180 - math.pi / 2;
      final innerRadius = radius - 15;
      final outerRadius = radius - 8;

      canvas.drawLine(
        Offset(
          center.dx + innerRadius * math.cos(angle),
          center.dy + innerRadius * math.sin(angle),
        ),
        Offset(
          center.dx + outerRadius * math.cos(angle),
          center.dy + outerRadius * math.sin(angle),
        ),
        paint,
      );
    }

    // Draw clock hands
    final handPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Hour hand
    canvas.drawLine(
      center,
      Offset(center.dx + 15, center.dy - 15),
      handPaint,
    );

    // Minute hand
    canvas.drawLine(
      center,
      Offset(center.dx + 5, center.dy - 25),
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium Fat Burned Card with dark green gradient and gauge effect
class PremiumFatBurnedCard extends StatelessWidget {
  final double fatGrams;
  final int animationDelay;

  const PremiumFatBurnedCard({
    super.key,
    required this.fatGrams,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AspectRatio(
          aspectRatio: 1.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF004D40), // Dark green
                  Color(0xFF00C853), // Oxygen green
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Gauge overlay background
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildGaugeOverlay(),
                  ),
                  // Radial glow in center
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner glow effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        // Value and label
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fatGrams.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 3, bottom: 4),
                                child: Text(
                                  'g',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Fat Burned',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  Widget _buildGaugeOverlay() {
    return SizedBox(
      width: 75,
      height: 75,
      child: CustomPaint(
        painter: _GaugePainter(),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw gauge arcs
    for (int i = 0; i < 3; i++) {
      final arcRadius = radius - (i * 12);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        math.pi * 0.75,
        math.pi * 1.5,
        false,
        paint,
      );
    }

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 10; i++) {
      final angle = math.pi * 0.75 + (i * math.pi * 1.5 / 10);
      final innerRadius = radius - 20;
      final outerRadius = radius - 5;

      canvas.drawLine(
        Offset(
          center.dx + innerRadius * math.cos(angle),
          center.dy + innerRadius * math.sin(angle),
        ),
        Offset(
          center.dx + outerRadius * math.cos(angle),
          center.dy + outerRadius * math.sin(angle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
