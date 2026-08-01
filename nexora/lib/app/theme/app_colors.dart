import 'package:flutter/material.dart';

/// Nexora brand + trust palette.
///
/// Colors are intentionally independent from the Material ColorScheme so that
/// trust semantics (green/blue/purple/orange/red) stay identical in both
/// light and dark mode.
abstract final class AppColors {
  // ---- Brand -------------------------------------------------------------
  static const Color brandSeed = Color(0xFF6C5CE7);
  static const Color brand = Color(0xFF7C6CF0);
  static const Color brandDeep = Color(0xFF4A3BB8);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentPink = Color(0xFFF472B6);

  // ---- Trust labels (color-coded) ---------------------------------------
  static const Color trustGreen = Color(0xFF22C55E); // Verified
  static const Color trustBlue = Color(0xFF3B82F6); // Vetted
  static const Color trustPurple = Color(0xFFA855F7); // Premium
  static const Color trustOrange = Color(0xFFF97316); // Watch
  static const Color trustRed = Color(0xFFEF4444); // Restricted

  // ---- Glass surfaces ----------------------------------------------------
  static const Color glassLight = Color(0x8CFFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassDark = Color(0x2EFFFFFF);
  static const Color glassBorderDark = Color(0x1FFFFFFF);

  // ---- Signature gradients ----------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, accentPink],
  );

  static const LinearGradient brandGradientDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandDeep, brand, accentCyan],
  );

  /// A copy of [gradient] with every color's opacity scaled by [alpha] (0–1).
  ///
  /// `Gradient.withValues` isn't available on this Flutter SDK, so tinting the
  /// signature gradients is done by fading each color instead.
  static LinearGradient faded(LinearGradient gradient, double alpha) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: [for (final c in gradient.colors) c.withValues(alpha: alpha)],
    );
  }

  static const LinearGradient feedStoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFD946EF), Color(0xFF8B5CF6)],
  );

  /// Material You seed variants derived from the brand.
  static const List<Color> seedOptions = [
    Color(0xFF6C5CE7),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];
}
