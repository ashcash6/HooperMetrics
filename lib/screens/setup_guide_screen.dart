import 'package:flutter/material.dart';

import 'camera_screen.dart';

class SetupGuideScreen extends StatelessWidget {
  static const String routeName = '/setup';

  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Setup Guide',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Camera placement diagram
                  Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: const _CameraPlacementDiagram(),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Before You Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._setupSteps.map(_buildStep),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, CameraScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  "I'm Ready — Start Recording",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _setupSteps = [
    _SetupStep(
      title: 'Use a tripod or stable surface',
      detail: 'Place your phone at hip height, about 10 feet away.',
      icon: Icons.videocam_outlined,
    ),
    _SetupStep(
      title: 'Stand sideways to the camera',
      detail: 'Your shooting side should face the lens.',
      icon: Icons.accessibility_new_outlined,
    ),
    _SetupStep(
      title: 'Full body in frame',
      detail: 'Head-to-toe should be visible at your shooting spot.',
      icon: Icons.crop_free_outlined,
    ),
    _SetupStep(
      title: 'First shot is a calibration',
      detail: 'Take one shot to start — the app uses it to calibrate and will not score it. All shots after count.',
      icon: Icons.tune_outlined,
    ),
    _SetupStep(
      title: 'Hold your follow-through',
      detail: 'Keep your hand up after each release.',
      icon: Icons.sports_basketball_outlined,
    ),
    _SetupStep(
      title: 'Stay put between shots',
      detail: "Don't walk away or celebrate — return to the same spot.",
      icon: Icons.do_not_disturb_alt_outlined,
    ),
  ];

  Widget _buildStep(_SetupStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(step.icon, color: const Color(0xFFFF6B00), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep {
  final String title;
  final String detail;
  final IconData icon;
  const _SetupStep({required this.title, required this.detail, required this.icon});
}

// ── Camera placement diagram ──────────────────────────────────────────────────

class _CameraPlacementDiagram extends StatelessWidget {
  const _CameraPlacementDiagram();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DiagramPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xFFFF6B00);
    const white = Colors.white;

    final W = size.width;
    final H = size.height;

    // Layout anchors
    final midX = W * 0.42; // slightly left of center so camera has room on right
    final basketY = H * 0.18;
    final playerY = H * 0.68;
    final camX = W * 0.83;
    final camY = playerY;

    // ── Subtle court lane (key) ───────────────────────────────────────────────
    final laneW = W * 0.22;
    final lanePaint = Paint()
      ..color = const Color(0xFF232323)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(midX - laneW / 2, basketY + 8, midX + laneW / 2, playerY + 4),
      lanePaint,
    );
    final laneStroke = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(midX - laneW / 2, basketY + 8, midX + laneW / 2, playerY + 4),
      laneStroke,
    );

    // ── Basket ────────────────────────────────────────────────────────────────
    // Backboard (horizontal bar)
    canvas.drawLine(
      Offset(midX - 18, basketY - 2),
      Offset(midX + 18, basketY - 2),
      Paint()
        ..color = white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Rim (orange circle)
    canvas.drawCircle(
      Offset(midX, basketY + 9),
      9,
      Paint()
        ..color = orange
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    // Net lines (3 short lines hanging down from rim)
    final netPaint = Paint()
      ..color = orange.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(midX + i * 6.0, basketY + 18),
        Offset(midX + i * 4.0, basketY + 26),
        netPaint,
      );
    }

    // ── Shot path (dashed line, player → basket) ──────────────────────────────
    _drawDashedLine(
      canvas, Offset(midX, playerY - 14), Offset(midX, basketY + 30),
      const Color(0xFF555555), 1.2, 7, 5,
    );
    // Arrow head at basket end
    final arrowPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(midX, basketY + 30), Offset(midX - 5, basketY + 38), arrowPaint);
    canvas.drawLine(Offset(midX, basketY + 30), Offset(midX + 5, basketY + 38), arrowPaint);

    // ── Player (YOU) ──────────────────────────────────────────────────────────
    // Body circle
    canvas.drawCircle(
      Offset(midX, playerY),
      14,
      Paint()..color = const Color(0xFF1F1F1F),
    );
    canvas.drawCircle(
      Offset(midX, playerY),
      14,
      Paint()
        ..color = white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    // Arrow inside player circle showing they face the basket
    final innerArrow = Paint()
      ..color = white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(midX, playerY + 5), Offset(midX, playerY - 5), innerArrow);
    canvas.drawLine(Offset(midX, playerY - 5), Offset(midX - 4, playerY + 1), innerArrow);
    canvas.drawLine(Offset(midX, playerY - 5), Offset(midX + 4, playerY + 1), innerArrow);

    // ── Camera ────────────────────────────────────────────────────────────────
    // Tripod legs
    final tripodPaint = Paint()
      ..color = orange.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(camX, camY + 10), Offset(camX - 9, camY + 28), tripodPaint);
    canvas.drawLine(Offset(camX, camY + 10), Offset(camX + 9, camY + 28), tripodPaint);
    canvas.drawLine(Offset(camX, camY + 10), Offset(camX, camY + 28), tripodPaint);

    // Camera body
    final camBodyPaint = Paint()
      ..color = orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final camFill = Paint()
      ..color = orange.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final camRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(camX, camY - 4), width: 30, height: 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(camRect, camFill);
    canvas.drawRRect(camRect, camBodyPaint);
    // Lens
    canvas.drawCircle(
      Offset(camX - 4, camY - 4),
      5,
      Paint()
        ..color = orange
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    // View-finder bump
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(camX + 5, camY - 10, 8, 5),
        const Radius.circular(2),
      ),
      Paint()
        ..color = orange
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // ── Distance line (player → camera) ──────────────────────────────────────
    _drawDashedLine(
      canvas, Offset(midX + 16, camY), Offset(camX - 18, camY),
      const Color(0xFF444444), 1, 6, 4,
    );

    // Right-angle indicator at player showing camera is 90° from shot path
    final raPaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const raS = 7.0;
    canvas.drawPath(
      Path()
        ..moveTo(midX + raS, playerY - raS)
        ..lineTo(midX + raS, playerY)
        ..lineTo(midX + raS * 2, playerY),
      raPaint,
    );

    // ── Labels ────────────────────────────────────────────────────────────────
    _label(canvas, 'BASKET', midX, basketY - 12, centered: true,
        style: const TextStyle(color: Color(0xFF888888), fontSize: 9, letterSpacing: 1));
    _label(canvas, 'YOU', midX, playerY + 19, centered: true,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5));
    _label(canvas, 'CAMERA', camX, camY + 32, centered: true,
        style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5));
    _label(canvas, 'hip height', camX, camY + 42, centered: true,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 8));
    _label(canvas, '~10 ft', (midX + 16 + camX - 18) / 2, camY - 13, centered: true,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 9));
    _label(canvas, '↑ shot direction', midX - 36, (basketY + playerY) / 2 - 6,
        style: const TextStyle(color: Color(0xFF444444), fontSize: 8, height: 1));

    // "TOP VIEW" badge top-right
    _label(canvas, 'TOP VIEW', W - 8, 8,
        style: const TextStyle(color: Color(0xFF3A3A3A), fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.w700),
        rightAlign: true);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end,
      Color color, double strokeWidth, double dashLen, double gapLen) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double walked = 0;
    bool drawing = true;
    while (walked < total) {
      final segLen = drawing ? dashLen : gapLen;
      final segEnd = (walked + segLen).clamp(0.0, total);
      if (drawing) {
        canvas.drawLine(
          start + dir * walked,
          start + dir * segEnd,
          paint,
        );
      }
      walked = segEnd;
      drawing = !drawing;
    }
  }

  void _label(Canvas canvas, String text, double x, double y, {
    TextStyle style = const TextStyle(color: Colors.white, fontSize: 10),
    bool centered = false,
    bool rightAlign = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = x;
    if (centered) dx = x - tp.width / 2;
    if (rightAlign) dx = x - tp.width;
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  bool shouldRepaint(_DiagramPainter old) => false;
}
