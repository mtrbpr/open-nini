import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme(Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB5446E),
      brightness: brightness,
    ),
  );
  final textTheme = GoogleFonts.vazirmatnTextTheme(base.textTheme).copyWith(
    bodyLarge: GoogleFonts.vazirmatn(textStyle: base.textTheme.bodyLarge, height: 1.7, fontSize: 16),
    bodyMedium: GoogleFonts.vazirmatn(textStyle: base.textTheme.bodyMedium, height: 1.65, fontSize: 15),
    titleMedium: GoogleFonts.vazirmatn(textStyle: base.textTheme.titleMedium, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.vazirmatn(textStyle: base.textTheme.titleLarge, fontWeight: FontWeight.w700),
  );
  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: base.colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: base.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
