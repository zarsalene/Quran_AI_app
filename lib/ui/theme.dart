import 'package:flutter/material.dart';

/// Rattil design tokens: paper, emerald, gold. One UI font (IBM Plex Sans
/// Arabic, Arabic and Latin), Amiri for titles, Amiri Quran for the text.
abstract final class RattilColors {
  static const emerald = Color(0xFF0E5A47);
  static const emeraldDeep = Color(0xFF083B2F);
  static const emeraldLight = Color(0xFF3FA585);
  static const gold = Color(0xFFC49A3A);
  static const goldLight = Color(0xFFE6C77A);
  static const paper = Color(0xFFFAF6EC);
  static const paperDeep = Color(0xFFF2EBD9);
  static const ink = Color(0xFF1C2622);
  static const night = Color(0xFF0D1412);
  static const nightSurface = Color(0xFF151F1C);
  static const nightCard = Color(0xFF1C2925);

  // Teacher marks: also readable for red-green color blindness (text labels
  // and backgrounds carry the meaning too).
  static const correct = Color(0xFF1E8A5A);
  static const check = Color(0xFFC0700F);
  static const mistake = Color(0xFFC6362E);
  static const unsure = Color(0xFF5B6E8C);
}

const uiFont = 'PlexArabic';
const titleFont = 'Amiri';
const quranFont = 'AmiriQuran';

ThemeData rattilTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? RattilColors.emeraldLight : RattilColors.emerald,
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xFF123F33) : const Color(0xFFD6EBE2),
    onPrimaryContainer: dark ? const Color(0xFFBFE6D6) : RattilColors.emeraldDeep,
    secondary: dark ? RattilColors.goldLight : RattilColors.gold,
    onSecondary: RattilColors.ink,
    secondaryContainer: dark ? const Color(0xFF3A3020) : const Color(0xFFF4E6C3),
    onSecondaryContainer: dark ? RattilColors.goldLight : const Color(0xFF5A4410),
    tertiary: RattilColors.check,
    onTertiary: Colors.white,
    error: RattilColors.mistake,
    onError: Colors.white,
    surface: dark ? RattilColors.night : RattilColors.paper,
    onSurface: dark ? const Color(0xFFE7E3D8) : RattilColors.ink,
    onSurfaceVariant: dark ? const Color(0xFFA9B3AE) : const Color(0xFF5F6B66),
    surfaceContainerLowest: dark ? RattilColors.night : Colors.white,
    surfaceContainerLow: dark ? RattilColors.nightSurface : const Color(0xFFFFFDF8),
    surfaceContainer: dark ? RattilColors.nightSurface : Colors.white,
    surfaceContainerHigh: dark ? RattilColors.nightCard : RattilColors.paperDeep,
    surfaceContainerHighest: dark ? const Color(0xFF24332E) : const Color(0xFFEAE2CD),
    outline: dark ? const Color(0xFF55625D) : const Color(0xFFB9B09A),
    outlineVariant: dark ? const Color(0xFF2C3A35) : const Color(0xFFE4DCC8),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: uiFont, brightness: b);
  final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final radius = BorderRadius.circular(20);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(fontFamily: uiFont, fontSize: 19, fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: uiFont, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: uiFont, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: const TextStyle(fontFamily: uiFont, fontWeight: FontWeight.w600)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.secondaryContainer,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: uiFont,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          )),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.secondary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: scheme.outlineVariant,
      labelStyle: const TextStyle(fontFamily: uiFont, fontWeight: FontWeight.w700, fontSize: 15),
      unselectedLabelStyle: const TextStyle(fontFamily: uiFont, fontWeight: FontWeight.w500, fontSize: 15),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(fontFamily: uiFont, color: scheme.onSurface, fontWeight: FontWeight.w500),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      titleTextStyle: TextStyle(fontFamily: uiFont, fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
      subtitleTextStyle: TextStyle(fontFamily: uiFont, fontSize: 13.5, color: scheme.onSurfaceVariant),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: scheme.surfaceContainerHighest),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
