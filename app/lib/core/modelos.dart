// ignore_for_file: constant_identifier_names

// Modelos de datos de la API. Cada uno sabe leerse desde JSON.

DateTime? _fechaHora(dynamic v) => v == null ? null : DateTime.parse(v as String);
DateTime _fecha(dynamic v) => DateTime.parse(v as String);

enum Rol { VECINO, FAMILIAR, VENDEDOR, AYUNTAMIENTO, ADMIN }

class Pueblo {
  final int id;
  final String nombre;
  final String? comarca;
  final int? habitantes;
  Pueblo({required this.id, required this.nombre, this.comarca, this.habitantes});
  factory Pueblo.fromJson(Map<String, dynamic> j) =>
      Pueblo(id: j['id'], nombre: j['nombre'], comarca: j['comarca'], habitantes: j['habitantes']);
}

class Usuario {
  final int id;
  final String username;
  final String nombre;
  final String? telefono;
  final Rol rol;
  final Pueblo? pueblo;
  final bool textoGrande;
  final String? codigoVinculo;
  final String? nombreComercial;
  final String? tipoVenta;
  Usuario({
    required this.id,
    required this.username,
    required this.nombre,
    this.telefono,
    required this.rol,
    this.pueblo,
    required this.textoGrande,
    this.codigoVinculo,
    this.nombreComercial,
    this.tipoVenta,
  });
  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
    id: j['id'],
    username: j['username'],
    nombre: j['nombre'],
    telefono: j['telefono'],
    rol: Rol.values.byName(j['rol']),
    pueblo: j['pueblo'] == null ? null : Pueblo.fromJson(j['pueblo']),
    textoGrande: j['textoGrande'] ?? true,
    codigoVinculo: j['codigoVinculo'],
    nombreComercial: j['vendedor']?['nombreComercial'],
    tipoVenta: j['vendedor']?['tipoEtiqueta'],
  );
}

/// Un vendedor que pasa hoy por el pueblo.
class Paso {
  final int rutaId;
  final int paradaId;
  final String vendedor;
  final String tipo;
  final String tipoEtiqueta;
  final String lugar;
  final String? hora;
  final String estado; // PREVISTA, EN_CAMINO, LLEGADO, SIN_SERVICIO_HOY
  final int? minutosFaltan;
  final int retrasoMin;
  final bool iniciada;
  Paso.fromJson(Map<String, dynamic> j)
    : rutaId = j['rutaId'],
      paradaId = j['paradaId'],
      vendedor = j['vendedor'],
      tipo = j['tipo'],
      tipoEtiqueta = j['tipoEtiqueta'],
      lugar = j['lugar'],
      hora = j['hora'],
      estado = j['estado'],
      minutosFaltan = j['minutosFaltan'],
      retrasoMin = j['retrasoMin'] ?? 0,
      iniciada = j['iniciada'] ?? false;
}

class Medico {
  final String estado; // CONSULTA, SIN_CONSULTA, NO_HAY
  final String? texto;
  final String? horaInicio;
  final String? horaFin;
  Medico.fromJson(Map<String, dynamic> j)
    : estado = j['estado'],
      texto = j['texto'],
      horaInicio = j['horaInicio'],
      horaFin = j['horaFin'];
}

class Aviso {
  final int id;
  final String tipo; // CONSULTA, SIN_CONSULTA, CAMBIO
  final DateTime fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? texto;
  final String resumen;
  Aviso.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      tipo = j['tipo'],
      fecha = _fecha(j['fecha']),
      horaInicio = j['horaInicio'],
      horaFin = j['horaFin'],
      texto = j['texto'],
      resumen = j['resumen'];
}

class Hoy {
  final Pueblo pueblo;
  final DateTime fecha;
  final DateTime actualizado;
  final List<Paso> pasos;
  final Medico medico;
  final List<Aviso> cambios;
  final List<Aviso> consultasSemana;
  Hoy.fromJson(Map<String, dynamic> j)
    : pueblo = Pueblo.fromJson(j['pueblo']),
      fecha = _fecha(j['fecha']),
      actualizado = _fechaHora(j['actualizado'])!,
      pasos = (j['pasos'] as List).map((e) => Paso.fromJson(e)).toList(),
      medico = Medico.fromJson(j['medico']),
      cambios = (j['cambios'] as List).map((e) => Aviso.fromJson(e)).toList(),
      consultasSemana = (j['consultasSemana'] as List).map((e) => Aviso.fromJson(e)).toList();
}

class ParadaEncargable {
  final int paradaId;
  final String lugar;
  final String vendedor;
  final String tipo;
  final String tipoEtiqueta;
  final String? horaHabitual;
  final List<DateTime> proximosDias;
  ParadaEncargable.fromJson(Map<String, dynamic> j)
    : paradaId = j['paradaId'],
      lugar = j['lugar'],
      vendedor = j['vendedor'],
      tipo = j['tipo'],
      tipoEtiqueta = j['tipoEtiqueta'],
      horaHabitual = j['horaHabitual'],
      proximosDias = (j['proximosDias'] as List).map((e) => _fecha(e)).toList();
}

class Encargo {
  final int? id;
  final DateTime fecha;
  final String texto;
  final String estado; // PENDIENTE, ENTREGADO, CANCELADO, o SIN_ENVIAR (solo en el móvil)
  final int paradaId;
  final String lugar;
  final String pueblo;
  final String vendedor;
  final String tipoEtiqueta;
  final String vecino;
  final String? telefonoVecino;
  final String? hechoPor;
  final String? idCliente;
  Encargo({
    this.id,
    required this.fecha,
    required this.texto,
    required this.estado,
    required this.paradaId,
    required this.lugar,
    required this.pueblo,
    required this.vendedor,
    required this.tipoEtiqueta,
    required this.vecino,
    this.telefonoVecino,
    this.hechoPor,
    this.idCliente,
  });
  factory Encargo.fromJson(Map<String, dynamic> j) => Encargo(
    id: j['id'],
    fecha: _fecha(j['fecha']),
    texto: j['texto'],
    estado: j['estado'],
    paradaId: j['paradaId'],
    lugar: j['lugar'],
    pueblo: j['pueblo'],
    vendedor: j['vendedor'],
    tipoEtiqueta: j['tipoEtiqueta'],
    vecino: j['vecino'],
    telefonoVecino: j['telefonoVecino'],
    hechoPor: j['hechoPor'],
    idCliente: j['idCliente'],
  );
}

class Notificacion {
  final int id;
  final String tipo;
  final String titulo;
  final String texto;
  final DateTime enviadaEn;
  final DateTime? vistaEn;
  final String? paraVecino;
  Notificacion.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      tipo = j['tipo'],
      titulo = j['titulo'],
      texto = j['texto'],
      enviadaEn = _fechaHora(j['enviadaEn'])!,
      vistaEn = _fechaHora(j['vistaEn']),
      paraVecino = j['paraVecino'];
}

class Suscripcion {
  final int id;
  final Pueblo pueblo;
  final String tipo;
  final String tipoEtiqueta;
  final int minAntes;
  Suscripcion.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      pueblo = Pueblo.fromJson(j['pueblo']),
      tipo = j['tipo'],
      tipoEtiqueta = j['tipoEtiqueta'],
      minAntes = j['minAntes'];
}

class VecinoVinculado {
  final int id;
  final String nombre;
  final String? telefono;
  final Pueblo? pueblo;
  final bool puedeEncargar;
  final Notificacion? ultimoAviso;
  VecinoVinculado.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      nombre = j['nombre'],
      telefono = j['telefono'],
      pueblo = j['pueblo'] == null ? null : Pueblo.fromJson(j['pueblo']),
      puedeEncargar = j['puedeEncargar'] ?? true,
      ultimoAviso = j['ultimoAviso'] == null ? null : Notificacion.fromJson(j['ultimoAviso']);
}

// ----------------------------------------------------------- vendedor

class ParadaHoy {
  final int paradaId;
  final int orden;
  final String pueblo;
  final String lugar;
  final String? hora;
  final String estado;
  final int encargosPendientes;
  final int encargosTotales;
  ParadaHoy.fromJson(Map<String, dynamic> j)
    : paradaId = j['paradaId'],
      orden = j['orden'],
      pueblo = j['pueblo'],
      lugar = j['lugar'],
      hora = j['hora'],
      estado = j['estado'],
      encargosPendientes = j['encargosPendientes'],
      encargosTotales = j['encargosTotales'];
}

class RutaHoy {
  final int rutaId;
  final String nombre;
  final bool tocaHoy;
  final String estadoJornada; // PREVISTA, EN_RUTA, TERMINADA
  final String? horaInicio;
  final String? horaSalidaHabitual;
  final int retrasoMin;
  final List<ParadaHoy> paradas;
  RutaHoy.fromJson(Map<String, dynamic> j)
    : rutaId = j['rutaId'],
      nombre = j['nombre'],
      tocaHoy = j['tocaHoy'],
      estadoJornada = j['estadoJornada'],
      horaInicio = j['horaInicio'],
      horaSalidaHabitual = j['horaSalidaHabitual'],
      retrasoMin = j['retrasoMin'] ?? 0,
      paradas = (j['paradas'] as List).map((e) => ParadaHoy.fromJson(e)).toList();

  ParadaHoy? get siguiente {
    for (final p in paradas) {
      if (p.estado == 'EN_CAMINO') return p;
    }
    return null;
  }
}

class Parada {
  final int? id;
  final Pueblo pueblo;
  final String lugar;
  final int minDesdeSalida;
  Parada({this.id, required this.pueblo, required this.lugar, required this.minDesdeSalida});
  factory Parada.fromJson(Map<String, dynamic> j) =>
      Parada(id: j['id'], pueblo: Pueblo.fromJson(j['pueblo']), lugar: j['lugar'], minDesdeSalida: j['minDesdeSalida']);
  Map<String, dynamic> toJson() => {'id': id, 'puebloId': pueblo.id, 'lugar': lugar, 'minDesdeSalida': minDesdeSalida};
}

class Ruta {
  final int id;
  final String nombre;
  final String diasSemana;
  final String? horaSalidaHabitual;
  final bool activa;
  final List<Parada> paradas;
  Ruta.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      nombre = j['nombre'],
      diasSemana = j['diasSemana'],
      horaSalidaHabitual = j['horaSalidaHabitual'],
      activa = j['activa'],
      paradas = (j['paradas'] as List).map((e) => Parada.fromJson(e)).toList();
}

class EncargosParada {
  final int paradaId;
  final int orden;
  final String pueblo;
  final String lugar;
  final String? hora;
  final List<Encargo> encargos;
  EncargosParada.fromJson(Map<String, dynamic> j)
    : paradaId = j['paradaId'],
      orden = j['orden'],
      pueblo = j['pueblo'],
      lugar = j['lugar'],
      hora = j['hora'],
      encargos = (j['encargos'] as List).map((e) => Encargo.fromJson(e)).toList();
}

class Semana {
  final DateTime lunes;
  final int encargos;
  final int entregados;
  final int cancelados;
  Semana.fromJson(Map<String, dynamic> j)
    : lunes = _fecha(j['lunes']),
      encargos = j['encargos'],
      entregados = j['entregados'],
      cancelados = j['cancelados'];
}

// ----------------------------------------------------------- ayuntamiento

class Panel {
  final Pueblo pueblo;
  final int vecinosSuscritos;
  final Hoy hoy;
  final List<Aviso> proximos;
  Panel.fromJson(Map<String, dynamic> j)
    : pueblo = Pueblo.fromJson(j['pueblo']),
      vecinosSuscritos = j['vecinosSuscritos'],
      hoy = Hoy.fromJson(j['hoy']),
      proximos = (j['proximos'] as List).map((e) => Aviso.fromJson(e)).toList();
}
