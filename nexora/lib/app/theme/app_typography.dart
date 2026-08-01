import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium typography system for Nexora.
///
/// Headings use Plus Jakarta Sans (modern, geometric) and body text uses
/// Inter (highly readable). Both gracefully fall back to the platform font
/// when Google Fonts cannot be fetched.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme(base);
    return GoogleFonts.interTextTheme(jakarta);
  }
}
