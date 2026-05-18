import 'package:flutter/material.dart';

/// Theme-adaptive colors injected as a ThemeExtension.
/// Access via `context.colors.*`.
/// kGoldColor and stage colors remain global constants (same in both themes).
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const dark = AppColors(
    background:    Color(0xFF111318),
    surface:       Color(0xFF1E2128),
    card:          Color(0xFF252932),
    textPrimary:   Color(0xFFE8EAF0),
    textSecondary: Color(0xFF9CA3AF),
    divider:       Color(0xFF2D3340),
  );

  static const light = AppColors(
    background:    Color(0xFFF4F5F7),
    surface:       Color(0xFFFFFFFF),
    card:          Color(0xFFFFFFFF),
    textPrimary:   Color(0xFF1A1D2E),
    textSecondary: Color(0xFF6B7280),
    divider:       Color(0xFFE5E7EB),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
  }) =>
      AppColors(
        background:    background    ?? this.background,
        surface:       surface       ?? this.surface,
        card:          card          ?? this.card,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        divider:       divider       ?? this.divider,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      card:          Color.lerp(card,          other.card,          t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider:       Color.lerp(divider,       other.divider,       t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
