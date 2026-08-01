import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'trust_models.dart';

/// Trust Center data fetched from the API.
class TrustOverview {
  const TrustOverview({
    this.history = const [],
    this.factors = const [],
    this.postsAnalyzed = 0,
    this.verifiedCount = 0,
    this.avgScore = 50,
  });

  final List<TrustHistoryPoint> history;
  final List<TrustFactor> factors;
  final int postsAnalyzed;
  final int verifiedCount;
  final int avgScore;
}

class TrustRepository {
  TrustRepository(this._api);

  final ApiClient _api;

  Future<TrustOverview> fetchOverview() async {
    final json = await _api.get('/trust/overview');
    final data = (json as Map<String, dynamic>?) ?? const {};
    final stats = (data['stats'] as Map<String, dynamic>?) ?? const {};
    const colors = [
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFA855F7),
      Color(0xFF22D3EE),
      Color(0xFFF59E0B),
    ];
    final factors = (data['factors'] as List?)
            ?.map((f) =>
                TrustFactor.fromApi(f as Map<String, dynamic>,
                    color: colors[(f['label'].hashCode % colors.length).abs()]))
            .toList() ??
        const [];
    return TrustOverview(
      history: (data['history'] as List?)
              ?.map((h) => TrustHistoryPoint.fromApi(h as Map<String, dynamic>))
              .toList() ??
          const [],
      factors: factors,
      postsAnalyzed: ((stats['postsAnalyzed'] as num?) ?? 0).toInt(),
      verifiedCount: ((stats['verifiedCount'] as num?) ?? 0).toInt(),
      avgScore: ((stats['avgScore'] as num?) ?? 50).toInt(),
    );
  }
}
