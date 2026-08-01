import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-selected theme preference.
enum AppThemeMode { system, light, dark }

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => AppThemeMode.dark;

  void setMode(AppThemeMode mode) => state = mode;

  void toggle() {
    state = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);

/// Resolves the effective Material [ThemeMode] from the user preference.
ThemeMode resolveThemeMode(AppThemeMode mode, Brightness platformBrightness) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return platformBrightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
  }
}
