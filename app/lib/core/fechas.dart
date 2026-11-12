// Fechas en español sin depender de paquetes externos.

const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String diaSemana(DateTime d) => _dias[d.weekday - 1];
String diaCorto(int isoDia) => _diasCortos[isoDia - 1];
String nombreDia(int isoDia) => _dias[isoDia - 1];

String dosCifras(int n) => n.toString().padLeft(2, '0');
String horaMinutos(DateTime d) => '${d.hour}:${dosCifras(d.minute)}';
String isoFecha(DateTime d) => '${d.year}-${dosCifras(d.month)}-${dosCifras(d.day)}';

bool mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// «Hoy», «Mañana», «El martes 17».
String cuando(DateTime d, {DateTime? hoy}) {
  final h = hoy ?? DateTime.now();
  if (mismoDia(d, h)) return 'Hoy';
  if (mismoDia(d, h.add(const Duration(days: 1)))) return 'Mañana';
  return 'El ${diaSemana(d)} ${d.day}';
}

/// «jueves 12 de noviembre».
String fechaLarga(DateTime d) => '${diaSemana(d)} ${d.day} de ${_meses[d.month - 1]}';

/// Quita los segundos de «10:40:00» o deja «10:40».
String hora(String? h) {
  if (h == null) return '--:--';
  final partes = h.split(':');
  return '${int.parse(partes[0])}:${partes[1]}';
}

/// «1,2,3,4,5,6» → «de lunes a sábado»; «2,4» → «martes y jueves».
String describirDias(String dias) {
  final n = dias.split(',').where((s) => s.trim().isNotEmpty).map((s) => int.parse(s.trim())).toList()..sort();
  if (n.length == 7) return 'todos los días';
  bool seguidos = n.length > 2;
  for (var i = 1; i < n.length; i++) {
    if (n[i] != n[i - 1] + 1) seguidos = false;
  }
  if (seguidos) return 'de ${nombreDia(n.first)} a ${nombreDia(n.last)}';
  final nombres = n.map(nombreDia).toList();
  if (nombres.length == 1) return 'los ${nombres.first}';
  return '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
}
