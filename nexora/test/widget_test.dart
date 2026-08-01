// Nexora widget + unit tests.
//
// These cover the pure, deterministic parts of the app (formatters, trust
// badges) so `flutter test` and `flutter analyze` stay green without
// requiring a backend or network mocks.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/core/models/user.dart';
import 'package:nexora/core/utils/formatters.dart';
import 'package:nexora/shared/widgets/trust_widgets.dart';

void main() {
  group('Formatters.compactCount', () {
    test('keeps small counts verbatim', () {
      expect(Formatters.compactCount(0), '0');
      expect(Formatters.compactCount(42), '42');
      expect(Formatters.compactCount(999), '999');
    });

    test('abbreviates thousands', () {
      expect(Formatters.compactCount(1000), '1.0K');
      expect(Formatters.compactCount(1234), '1.2K');
      expect(Formatters.compactCount(99999), '100.0K');
    });

    test('abbreviates millions', () {
      expect(Formatters.compactCount(1000000), '1.0M');
      expect(Formatters.compactCount(2300000), '2.3M');
    });
  });

  group('Formatters.timeAgo', () {
    final now = DateTime(2026, 8, 1, 12, 0, 0);

    test('returns relative units', () {
      expect(
        Formatters.timeAgo(now.subtract(const Duration(seconds: 10)), now: now),
        'now',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(hours: 2)), now: now),
        '2h',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3d',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 14)), now: now),
        '2w',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 90)), now: now),
        '3mo',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 400)), now: now),
        '1y',
      );
    });
  });

  group('TrustBadge', () {
    testWidgets('renders the label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrustBadge(label: TrustLabel.verified),
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('compact variant still shows the label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrustBadge(label: TrustLabel.restricted, compact: true),
          ),
        ),
      );

      expect(find.text('Restricted'), findsOneWidget);
    });
  });

  group('TrustLabel.fromScore', () {
    test('maps scores to labels', () {
      expect(TrustLabel.fromScore(90), TrustLabel.verified);
      expect(TrustLabel.fromScore(75), TrustLabel.vetted);
      expect(TrustLabel.fromScore(60), TrustLabel.premium);
      expect(TrustLabel.fromScore(45), TrustLabel.watch);
      expect(TrustLabel.fromScore(20), TrustLabel.restricted);
    });
  });
}
