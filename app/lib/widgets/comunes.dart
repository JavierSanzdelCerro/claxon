import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/tema.dart';

class Cargando extends StatelessWidget {
  const Cargando({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
    ),
  );
}

class ErrorReintentar extends StatelessWidget {
  final Object error;
  final VoidCallback onReintentar;
  const ErrorReintentar({super.key, required this.error, required this.onReintentar});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 56, color: Tema.gris),
          const SizedBox(height: 12),
          Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

/// Franja que avisa de que se están viendo datos guardados (sin conexión).
class SinConexion extends StatelessWidget {
  final DateTime guardadoEn;
  const SinConexion({super.key, required this.guardadoEn});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      color: const Color(0xFFFFF1C2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Tema.tinta),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión. Datos guardados a las ${horaMinutos(guardadoEn)}.',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

class Titulo extends StatelessWidget {
  final String texto;
  final Widget? accion;
  const Titulo(this.texto, {super.key, this.accion});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleMedium)),
        ),
        ?accion,
      ],
    ),
  );
}

/// Insignia de color con icono y texto (nunca solo icono, RNF1).
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData? icono;
  const Etiqueta(this.texto, {super.key, required this.color, this.icono});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[Icon(icono, size: 18, color: Colors.white), const SizedBox(width: 4)],
        Text(
          texto,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Tema.rojo : Tema.verde,
        duration: const Duration(seconds: 4),
      ),
    );
}

void mostrarError(BuildContext context, Object e) =>
    mostrarMensaje(context, e is ApiError ? e.mensaje : 'Algo ha fallado: $e', error: true);

Future<bool> confirmar(BuildContext context, String pregunta, {String si = 'Sí', String no = 'No'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(pregunta, style: Theme.of(c).textTheme.bodyLarge),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(c, false), child: Text(no)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(si)),
      ],
    ),
  );
  return r ?? false;
}

/// Botón de la demo para adelantar el reloj del servidor (solo aparece si el servidor está en modo demo).
class BotonRelojDemo extends StatefulWidget {
  final VoidCallback? onCambio;
  const BotonRelojDemo({super.key, this.onCambio});
  @override
  State<BotonRelojDemo> createState() => _BotonRelojDemoState();
}

class _BotonRelojDemoState extends State<BotonRelojDemo> {
  DateTime? _hora;

  @override
  void initState() {
    super.initState();
    Api.i.relojDemo().then((h) => mounted ? setState(() => _hora = h) : null);
  }

  Future<void> _adelantar(int min) async {
    final h = await Api.i.adelantarReloj(min);
    if (!mounted) return;
    setState(() => _hora = h);
    widget.onCambio?.call();
    mostrarMensaje(
      context,
      min == 0 ? 'Reloj en hora real' : 'Reloj del servidor: ${h == null ? '?' : horaMinutos(h)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hora == null) return const SizedBox.shrink();
    return PopupMenuButton<int>(
      tooltip: 'Reloj de la demo',
      icon: const Icon(Icons.fast_forward),
      onSelected: _adelantar,
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text('Demo · servidor ${horaMinutos(_hora!)}')),
        const PopupMenuItem(value: 5, child: Text('Adelantar 5 min')),
        const PopupMenuItem(value: 15, child: Text('Adelantar 15 min')),
        const PopupMenuItem(value: 30, child: Text('Adelantar 30 min')),
        const PopupMenuItem(value: 0, child: Text('Volver a la hora real')),
      ],
    );
  }
}
