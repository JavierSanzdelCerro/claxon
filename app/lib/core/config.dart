import 'package:flutter/foundation.dart';

/// Dirección del servidor.
/// - En web, si la app la sirve el propio Spring Boot, se usa el mismo origen.
/// - En Android, por defecto el emulador ve el ordenador en 10.0.2.2.
/// - Siempre se puede forzar con: flutter run --dart-define=API_URL=https://mi-servidor
class Config {
  static const String _definida = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_definida.isNotEmpty) return _definida;
    if (kIsWeb) {
      final base = Uri.base;
      // En desarrollo (flutter run -d chrome) el servidor está en el 8080.
      if (base.port != 8080 && (base.host == 'localhost' || base.host == '127.0.0.1')) {
        return 'http://${base.host}:8080';
      }
      return base.origin;
    }
    return 'http://10.0.2.2:8080';
  }

  /// Cada cuánto se consultan avisos nuevos y se reintenta la cola sin conexión.
  static const Duration intervaloSondeo = Duration(seconds: 20);
}
