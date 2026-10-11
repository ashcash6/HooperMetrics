import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pose_data.dart';
import '../models/session.dart';
import '../services/session_repository.dart';
import 'shot_review_screen.dart';

class ResultScreen extends StatefulWidget {
  final double overallScore;
  final Map<String, double> detailedScores;
  final List<String> tips;
  final List<List<PoseData>> shots;
  final List<String> shotVideoPaths;
  final String? videoPath;

  static const String routeName = '/result';

  const ResultScreen({
    super.key,
    required this.overallScore,
    required this.detailedScores,
    required this.tips,
    required this.shots,
    required this.shotVideoPaths,
    this.videoPath,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _saveSession();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    final session = Session(
      date: DateTime.now(),
      overallScore: widget.overallScore,
      detailedScores: widget.detailedScores,
      tips: widget.tips,
      shotCount: widget.shots.length,
    );
    await SessionRepository.instance.save(session);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _scoreColor(double pct) {
    if (pct < 50) return Colors.redAccent;
    if (pct < 70) return Colors.amber;
    if (pct < 88) return const Color(0xFFFF6B00);
    return Colors.greenAccent;
  }

  String _scoreLabel(double pct) {
    if (pct < 50) return 'Needs Work';
    if (pct < 70) return 'Developing';
    if (pct < 88) return 'Solid Form';
    return 'Elite';
  }

  String _metricLabel(String key) {
    switch (key) {
      case 'right_elbow_angle':
        return 'Shooting Elbow';
      case 'left_elbow_angle':
        return 'Guide Arm Elbow';
      case 'right_knee_angle':
        return 'Shooting-Side Knee';
      case 'left_knee_angle':
        return 'Off-Side Knee';
      case 'right_shoulder_angle':
        return 'Shooting Shoulder';
      case 'left_shoulder_angle':
        return 'Guide Arm Shoulder';
      default:
        return key;
    }
  }

  String _formatTip(String raw) {
    final i = raw.indexOf(':');
    return i > 0 ? raw.substring(i + 1).trim() : raw;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const allowedMetrics = {
      'right_elbow_angle',
      'left_elbow_angle',
      'right_knee_angle',
      'left_knee_angle',
      'right_shoulder_angle',
      'left_shoulder_angle',
    };

    final filteredScores = widget.detailedScores.entries
        .where((e) => allowedMetrics.contains(e.key))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final hasScore = widget.overallScore >= 0;
    final overallPct = hasScore ? (widget.overallScore * 100).clamp(0.0, 100.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: const Color(0xFF0F0F0F),
                expandedHeight: 260,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF0F0F0F),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              // Circular arc gauge
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(150, 150),
                                      painter: _ArcPainter(
                                        progress: hasScore ? _anim.value * (overallPct / 100) : 0,
                                        color: hasScore ? _scoreColor(overallPct) : const Color(0xFF333333),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          hasScore
                                              ? '${(overallPct * _anim.value).toStringAsFixed(0)}%'
                                              : '—',
                                          style: TextStyle(
                                            color: hasScore ? _scoreColor(overallPct) : const Color(0xFF666666),
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        if (hasScore)
                                          Text(
                                            _scoreLabel(overallPct),
                                            style: TextStyle(
                                              color: _scoreColor(overallPct).withValues(alpha: 0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hasScore
                                    ? 'Shot Consistency Score'
                                    : 'Record 2+ shots for a score',
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Mechanics breakdown
                    if (filteredScores.isNotEmpty) ...[
                      _sectionHeader('Mechanics Breakdown'),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF151515),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF222222)),
                          ),
                          child: Column(
                            children: filteredScores.asMap().entries.map((e) {
                              final i = e.key;
                              final entry = e.value;
                              final pct = (entry.value * 100).clamp(0.0, 100.0);
                              return _MetricRow(
                                label: _metricLabel(entry.key),
                                percent: pct,
                                color: _scoreColor(pct),
                                divider: i < filteredScores.length - 1,
                                animValue: _anim.value,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Coach's feedback
                    _sectionHeader("Coach's Feedback"),
                    const SizedBox(height: 12),
                    ...widget.tips.map(
                      (tip) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B00),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatTip(tip),
                                style: const TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Floating bottom bar ───────────────────────────────────────────────
          if (widget.shotVideoPaths.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 44),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  border: const Border(top: BorderSide(color: Color(0xFF1E1E1E))),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShotReviewScreen(
                        shots: widget.shots,
                        shotVideoPaths: widget.shotVideoPaths,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                  label: Text(
                    widget.shotVideoPaths.length == 1
                        ? 'Watch Your Shot'
                        : 'Watch Your ${widget.shotVideoPaths.length} Shots',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Metric row ────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final bool divider;
  final double animValue;

  const _MetricRow({
    required this.label,
    required this.percent,
    required this.color,
    required this.divider,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
                  Text(
                    '${(percent * animValue).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percent / 100) * animValue,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        if (divider) const Divider(height: 1, color: Color(0xFF222222), indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Arc gauge painter ─────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    const startAngle = pi * 0.7;
    const sweepFull = pi * 1.6;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - stroke / 2,
    );

    // Track
    canvas.drawArc(
      rect,
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = const Color(0xFF242424)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (progress > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepFull * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress || old.color != color;
}
