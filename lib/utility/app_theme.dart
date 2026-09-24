import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Extra colours that Material's ColorScheme doesn't have a slot for.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.soft,
    required this.field,
    required this.accent,
  });

  final Color bg;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final Color soft;
  final Color field;
  final Color accent;

  static const light = AppPalette(
    bg: AppColors.bgLight,
    card: AppColors.cardLight,
    ink: AppColors.inkLight,
    muted: AppColors.mutedLight,
    line: AppColors.lineLight,
    soft: AppColors.softLight,
    field: AppColors.fieldLight,
    accent: AppColors.primary,
  );

  static const dark = AppPalette(
    bg: AppColors.bgDark,
    card: AppColors.cardDark,
    ink: AppColors.inkDark,
    muted: AppColors.mutedDark,
    line: AppColors.lineDark,
    soft: AppColors.softDark,
    field: AppColors.fieldDark,
    accent: AppColors.primaryOnDark,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? card,
    Color? ink,
    Color? muted,
    Color? line,
    Color? soft,
    Color? field,
    Color? accent,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      soft: soft ?? this.soft,
      field: field ?? this.field,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      field: Color.lerp(field, other.field, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  AppTheme._();

  /// Display face for headings and big numbers.
  static TextStyle display({double size = 24, FontWeight weight = FontWeight.w700, Color? color, double? height}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle mono({double size = 12, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness).copyWith(
      primary: p.accent,
      onPrimary: Colors.white,
      surface: p.card,
      onSurface: p.ink,
      error: AppColors.error,
      outline: p.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);

    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.ink,
        titleTextStyle: display(size: 22, color: p.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
        prefixIconColor: p.muted,
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.accent, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: p.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: isDark ? AppColors.softDark : AppColors.deep,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
