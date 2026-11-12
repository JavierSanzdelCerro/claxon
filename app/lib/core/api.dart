import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'modelos.dart';

/// Error que se puede enseñar tal cual al usuario.
class ApiError implements Exception {
  final String mensaje;
  final int? status;
  final bool sinConexion;
  ApiError(this.mensaje, {this.status, this.sinConexion = false});
  @override
  String toString() => mensaje;
}

/// Respuesta que puede venir del servidor o de la copia guardada en el móvil (sin conexión, RF15).
class Guardado<T> {
  final T datos;
  final bool deCache;
  final DateTime guardadoEn;
  Guardado(this.datos, this.deCache, this.guardadoEn);
}

/// Cliente de la API REST de CLAXON. Guarda el token y una copia de las respuestas importantes.
class Api {
  Api._();
  static final Api i = Api._();

  static const _kToken = 'token';
  static const _kCache = 'cache:';
  static const _kCola = 'cola_encargos';
  static const _timeout = Duration(seconds: 12);

  SharedPreferences? _prefs;
  String? _token;
  Usuario? usuario;

  /// Avisa a la interfaz de que hay que volver a la pantalla de login (sesión caducada).
  final StreamController<void> sesionCerrada = StreamController.broadcast();

  Future<SharedPreferences> get prefs async => _prefs ??= await SharedPreferences.getInstance();

  bool get conSesion => _token != null;

  /// Recupera la sesión guardada. Si no hay red, usa el último usuario conocido.
  Future<Usuario?> iniciar() async {
    final p = await prefs;
    _token = p.getString(_kToken);
    if (_token == null) return null;
    try {
      final r = await guardando<Map<String, dynamic>>('/api/me');
      usuario = Usuario.fromJson(r.datos);
      return usuario;
    } on ApiError catch (e) {
      if (e.status == 401) {
        await cerrarSesion();
        return null;
      }
      rethrow;
    }
  }

  Future<Usuario> login(String username, String password) async {
    final r = await post('/api/auth/login', {'username': username, 'password': password}, false);
    return _guardarSesion(r);
  }

  Future<Usuario> registrar(Map<String, dynamic> datos) async {
    final r = await post('/api/auth/registro', datos, false);
    return _guardarSesion(r);
  }

  Future<Usuario> _guardarSesion(dynamic r) async {
    _token = r['token'];
    usuario = Usuario.fromJson(r['usuario']);
    final p = await prefs;
    await p.setString(_kToken, _token!);
    await p.setString('$_kCache/api/me', jsonEncode({'t': DateTime.now().toIso8601String(), 'd': r['usuario']}));
    return usuario!;
  }

  Future<void> cerrarSesion() async {
    final p = await prefs;
    for (final k in p.getKeys().toList()) {
      if (k == _kToken || k.startsWith(_kCache) || k == _kCola) await p.remove(k);
    }
    _token = null;
    usuario = null;
  }

  Future<Usuario> recargarUsuario() async {
    usuario = Usuario.fromJson(await get('/api/me'));
    return usuario!;
  }

  // ------------------------------------------------------------------ HTTP

  Map<String, String> _cabeceras(bool autenticado) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    if (autenticado && _token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String ruta) => Uri.parse('${Config.apiUrl}$ruta');

  Future<dynamic> get(String ruta, {bool autenticado = true}) =>
      _enviar(() => http.get(_uri(ruta), headers: _cabeceras(autenticado)));

  Future<dynamic> post(String ruta, [Object? cuerpo, bool autenticado = true]) async => _enviar(
    () => http.post(_uri(ruta), headers: _cabeceras(autenticado), body: cuerpo == null ? null : jsonEncode(cuerpo)),
  );

  Future<dynamic> put(String ruta, Object cuerpo) =>
      _enviar(() => http.put(_uri(ruta), headers: _cabeceras(true), body: jsonEncode(cuerpo)));

  Future<dynamic> delete(String ruta) => _enviar(() => http.delete(_uri(ruta), headers: _cabeceras(true)));

  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    http.Response r;
    try {
      r = await peticion().timeout(_timeout);
    } on TimeoutException {
      throw ApiError('No hay conexión. Lo intentaremos de nuevo.', sinConexion: true);
    } catch (_) {
      throw ApiError('No hay conexión. Lo intentaremos de nuevo.', sinConexion: true);
    }
    final texto = utf8.decode(r.bodyBytes);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return texto.isEmpty ? null : jsonDecode(texto);
    }
    if (r.statusCode == 401 && _token != null) {
      sesionCerrada.add(null);
    }
    String mensaje = 'Algo ha fallado (${r.statusCode})';
    try {
      mensaje = jsonDecode(texto)['error'] ?? mensaje;
    } catch (_) {}
    if (r.statusCode == 401 && _token == null) mensaje = 'Usuario o contraseña incorrectos';
    throw ApiError(mensaje, status: r.statusCode);
  }

  /// GET que guarda una copia en el móvil y, si no hay red, devuelve la última copia.
  Future<Guardado<T>> guardando<T>(String ruta) async {
    final p = await prefs;
    try {
      final datos = await get(ruta);
      await p.setString('$_kCache$ruta', jsonEncode({'t': DateTime.now().toIso8601String(), 'd': datos}));
      return Guardado(datos as T, false, DateTime.now());
    } on ApiError catch (e) {
      if (!e.sinConexion) rethrow;
      final copia = p.getString('$_kCache$ruta');
      if (copia == null) rethrow;
      final j = jsonDecode(copia);
      return Guardado(j['d'] as T, true, DateTime.parse(j['t']));
    }
  }

  // ------------------------------------------------------- cola sin conexión

  static String nuevoIdCliente() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Guarda un encargo que no se pudo enviar. Se reenvía solo al volver la cobertura.
  Future<void> encolarEncargo(Map<String, dynamic> peticion, Map<String, dynamic> paraMostrar) async {
    final p = await prefs;
    final cola = _leerCola(p)..add({'peticion': peticion, 'mostrar': paraMostrar});
    await p.setString(_kCola, jsonEncode(cola));
  }

  List<Map<String, dynamic>> _leerCola(SharedPreferences p) {
    final t = p.getString(_kCola);
    if (t == null) return [];
    return (jsonDecode(t) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Encargo>> encargosSinEnviar({int? vecinoId}) async {
    final p = await prefs;
    return _leerCola(p)
        .where((e) => e['peticion']['vecinoId'] == vecinoId)
        .map(
          (e) => Encargo(
            fecha: DateTime.parse(e['peticion']['fecha']),
            texto: e['peticion']['texto'],
            estado: 'SIN_ENVIAR',
            paradaId: e['peticion']['paradaId'],
            lugar: e['mostrar']['lugar'] ?? '',
            pueblo: e['mostrar']['pueblo'] ?? '',
            vendedor: e['mostrar']['vendedor'] ?? '',
            tipoEtiqueta: e['mostrar']['tipoEtiqueta'] ?? '',
            vecino: '',
            idCliente: e['peticion']['idCliente'],
          ),
        )
        .toList();
  }

  bool _vaciando = false;

  /// Intenta enviar lo pendiente. Devuelve cuántos se enviaron.
  Future<int> vaciarCola() async {
    if (_vaciando || _token == null) return 0;
    _vaciando = true;
    var enviados = 0;
    try {
      final p = await prefs;
      final cola = _leerCola(p);
      final quedan = <Map<String, dynamic>>[];
      for (final e in cola) {
        try {
          await post('/api/encargos', e['peticion']);
          enviados++;
        } on ApiError catch (err) {
          // Sin red: se queda en la cola. Error del servidor (p. ej. día pasado): se descarta.
          if (err.sinConexion) quedan.add(e);
        }
      }
      await p.setString(_kCola, jsonEncode(quedan));
    } finally {
      _vaciando = false;
    }
    return enviados;
  }

  // ------------------------------------------------------------- atajos

  Future<Guardado<Hoy>> hoyDePueblo(int puebloId) async {
    final r = await guardando<Map<String, dynamic>>('/api/pueblos/$puebloId/hoy');
    return Guardado(Hoy.fromJson(r.datos), r.deCache, r.guardadoEn);
  }

  Future<List<Pueblo>> buscarPueblos(String q) async {
    final r = await get('/api/pueblos?q=${Uri.encodeQueryComponent(q)}', autenticado: false) as List;
    return r.map((e) => Pueblo.fromJson(e)).toList();
  }

  String _vecino(int? vecinoId) => vecinoId == null ? '' : '?vecinoId=$vecinoId';

  Future<Guardado<List<Encargo>>> encargos({int? vecinoId}) async {
    final r = await guardando<List<dynamic>>('/api/encargos${_vecino(vecinoId)}');
    return Guardado(r.datos.map((e) => Encargo.fromJson(e)).toList(), r.deCache, r.guardadoEn);
  }

  Future<List<Suscripcion>> suscripciones({int? vecinoId}) async {
    final r = await get('/api/suscripciones${_vecino(vecinoId)}') as List;
    return r.map((e) => Suscripcion.fromJson(e)).toList();
  }

  Future<List<Notificacion>> notificaciones({DateTime? desde}) async {
    final q = desde == null ? '' : '?desde=${Uri.encodeQueryComponent(desde.toIso8601String().split('.').first)}';
    final r = await get('/api/notificaciones$q') as List;
    return r.map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<List<ParadaEncargable>> paradasDe(int puebloId) async {
    final r = await guardando<List<dynamic>>('/api/pueblos/$puebloId/paradas');
    return r.datos.map((e) => ParadaEncargable.fromJson(e)).toList();
  }

  // --------------------------------------------------------------- demo

  /// Adelanta el reloj del servidor (solo en modo demo). Devuelve la hora del servidor o null si no hay demo.
  Future<DateTime?> adelantarReloj(int minutos) async {
    try {
      final r = await post('/api/public/demo/reloj?minutos=$minutos', null, false);
      return DateTime.parse(r['ahora']);
    } on ApiError {
      return null;
    }
  }

  Future<DateTime?> relojDemo() async {
    try {
      final r = await get('/api/public/demo/reloj', autenticado: false);
      return DateTime.parse(r['ahora']);
    } on ApiError {
      return null;
    }
  }
}
