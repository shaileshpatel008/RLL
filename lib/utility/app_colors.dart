import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B2FC9);
  static const Color primaryDark = Color(0xFF3F1D96);
  static const Color primaryOnDark = Color(0xFF8E6BFF);
  static const Color deep = Color(0xFF221450);
  static const Color splash = Color(0xFF1B0F45);

  // Rainbow (taken from the logo)
  static const Color red = Color(0xFFE53935);
  static const Color orange = Color(0xFFFB8C00);
  static const Color yellow = Color(0xFFFDD835);
  static const Color green = Color(0xFF43A047);
  static const Color blue = Color(0xFF1E88E5);
  static const Color violet = Color(0xFF7E57C2);
  static const List<Color> rainbow = [red, orange, yellow, green, blue, violet];

  // Light surfaces
  static const Color bgLight = Color(0xFFF5F3FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color inkLight = Color(0xFF1A1530);
  static const Color mutedLight = Color(0xFF625C78);
  static const Color lineLight = Color(0xFFE6E1F0);
  static const Color softLight = Color(0xFFEEE8FC);
  static const Color fieldLight = Color(0xFFF8F7FC);

  // Dark surfaces
  static const Color bgDark = Color(0xFF0F0B1E);
  static const Color cardDark = Color(0xFF1A1530);
  static const Color inkDark = Color(0xFFF3F0FB);
  static const Color mutedDark = Color(0xFFA9A3BF);
  static const Color lineDark = Color(0xFF2C2548);
  static const Color softDark = Color(0xFF261E48);
  static const Color fieldDark = Color(0xFF211A3C);

  // Status
  static const Color success = Color(0xFF1E8E3E);
  static const Color error = Color(0xFFB3261E);
  static const Color errorSoft = Color(0xFFFDE7E6);
  static const Color warning = Color(0xFF9A4A00);
  static const Color info = Color(0xFF0F5AA8);

  /// Soft background / strong foreground pairs used for avatars and icon tiles.
  static const List<(Color, Color)> tones = [
    (Color(0xFFFDE7E6), Color(0xFFB3261E)),
    (Color(0xFFFFEFD9), Color(0xFF9A4A00)),
    (Color(0xFFE4F4E5), Color(0xFF1E6B25)),
    (Color(0xFFE2EFFC), Color(0xFF0F5AA8)),
    (Color(0xFFEEE8FC), Color(0xFF4B23B0)),
    (Color(0xFFFFF6CC), Color(0xFF7A5B00)),
  ];

  static (Color, Color) toneFor(String key) {
    final hash = key.codeUnits.fold<int>(0, (a, b) => (a + b) % 997);
    return tones[hash % tones.length];
  }
}
