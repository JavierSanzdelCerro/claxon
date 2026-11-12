import 'package:material_ui/material_ui.dart';

/// Colores y tipografía pensados para personas mayores (RNF1):
/// texto base de 18, contraste AA o mejor y botones de al menos 56 de alto.
class Tema {
  static const verde = Color(0xFF0B5D4B); // principal: contraste 7,6:1 sobre blanco
  static const ambar = Color(0xFFF2A900); // acento, el color del «claxon»
  static const rojo = Color(0xFFB3261E);
  static const fondo = Color(0xFFFAF8F3);
  static const tinta = Color(0xFF1B1B1B);
  static const gris = Color(0xFF555555); // 7,4:1 sobre fondo

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: verde,
      primary: verde,
      secondary: ambar,
      error: rojo,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    final base = ThemeData(colorScheme: esquema, useMaterial3: true, fontFamily: 'Atkinson');
    final texto = base.textTheme
        .apply(bodyColor: tinta, displayColor: tinta)
        .copyWith(
          bodyLarge: const TextStyle(fontSize: 20, height: 1.35, color: tinta),
          bodyMedium: const TextStyle(fontSize: 18, height: 1.35, color: tinta),
          bodySmall: const TextStyle(fontSize: 16, height: 1.3, color: gris),
          titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tinta),
          titleMedium: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: tinta),
          titleSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tinta),
          labelLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          headlineMedium: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: tinta),
        )
        .apply(fontFamily: 'Atkinson');
    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      textTheme: texto,
      appBarTheme: const AppBarTheme(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 60),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          side: const BorderSide(color: verde, width: 2),
          foregroundColor: verde,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: verde,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(fontSize: 18),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2DED3)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: ambar.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        iconTheme: WidgetStateProperty.all(const IconThemeData(size: 30, color: tinta)),
      ),
      chipTheme: base.chipTheme.copyWith(labelStyle: const TextStyle(fontSize: 18)),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  static IconData icono(String tipo) => switch (tipo) {
    'PAN' => Icons.bakery_dining,
    'PESCADO' => Icons.set_meal,
    'FRUTA' => Icons.eco,
    'CARNE' => Icons.kebab_dining,
    'MEDICO' => Icons.medical_services,
    _ => Icons.local_shipping,
  };

  static Color colorTipo(String tipo) => switch (tipo) {
    'PAN' => const Color(0xFF8A4B08),
    'PESCADO' => const Color(0xFF0B4F8A),
    'FRUTA' => const Color(0xFF2E6B12),
    'CARNE' => const Color(0xFF8A1C1C),
    'MEDICO' => const Color(0xFF6A1B9A),
    _ => verde,
  };
}
