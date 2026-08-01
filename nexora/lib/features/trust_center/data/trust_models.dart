import 'package:flutter/material.dart';

/// Weekly trust score history point.
class TrustHistoryPoint {
  const TrustHistoryPoint({required this.week, required this.score});

  final String week;
  final double score;

  factory TrustHistoryPoint.fromApi(Map<String, dynamic> json) {
    return TrustHistoryPoint(
      week: (json['week'] as String?) ?? 'W?',
      score: ((json['score'] as num?) ?? 0).toDouble(),
    );
  }
}

/// A factor that composes the Trust Score.
class TrustFactor {
  const TrustFactor(this.label, this.value, this.color);

  final String label;
  final double value; // 0..100
  final Color color;

  factory TrustFactor.fromApi(Map<String, dynamic> json, {Color color = const Color(0xFF3B82F6)}) {
    return TrustFactor(
      (json['label'] as String?) ?? 'Factor',
      ((json['value'] as num?) ?? 0).clamp(0, 100).toDouble(),
      color,
    );
  }
}
