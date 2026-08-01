import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/user.dart';

/// Color-coded Trust Label pill used on posts, profiles and reels.
class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, required this.label, this.compact = false});

  final TrustLabel label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = label.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated semicircular Trust Score gauge.
class TrustScoreGauge extends StatelessWidget {
  const TrustScoreGauge({
    super.key,
    required this.score,
    this.size = 200,
    this.showLabel = true,
  });

  final double score;
  final double size;
  final bool showLabel;

  Color get _color => TrustLabel.fromScore(score).color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size * 0.62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size * 0.62),
                painter: _GaugePainter(
                  value: value,
                  color: _color,
                  trackColor: scheme.surfaceContainerHighest,
                ),
              ),
              Positioned(
                bottom: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.round().toString(),
                      style: TextStyle(
                        fontSize: size * 0.19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: _color,
                      ),
                    ),
                    if (showLabel)
                      Text(
                        'Trust Score',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = math.min(size.width, size.height * 2) / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * (value / 100), false, progress);

    // Center cap
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

/// Linear trust bar used in the Trust Center factor list.
class TrustBar extends StatelessWidget {
  const TrustBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value; // 0..100
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
            Text(
              '${value.round()}%',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v / 100,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
