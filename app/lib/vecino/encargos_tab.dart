import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Mis encargos: pendientes, entregados y los que esperan a tener conexión (RF6).
class EncargosTab extends StatefulWidget {
  final int? vecinoId;
  final VoidCallback onNuevo;
  const EncargosTab({super.key, this.vecinoId, required this.onNuevo});
  @override
  State<EncargosTab> createState() => EncargosTabState();
}

class EncargosTabState extends State<EncargosTab> {
  Guardado<List<Encargo>>? _datos;
  List<Encargo> _sinEnviar = [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      final d = await Api.i.encargos(vecinoId: widget.vecinoId);
      final s = await Api.i.encargosSinEnviar(vecinoId: widget.vecinoId);
      if (mounted) {
        setState(() {
          _datos = d;
          _sinEnviar = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _cancelar(Encargo e) async {
    if (!await confirmar(context, '¿Cancelar el encargo «${e.texto}»?', si: 'Sí, cancelar', no: 'No')) return;
    try {
      await Api.i.post('/api/encargos/${e.id}/cancelar');
      await recargar();
      if (mounted) mostrarMensaje(context, 'Encargo cancelado');
    } catch (err) {
      if (mounted) mostrarError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_datos == null && _error != null) return ErrorReintentar(error: _error!, onReintentar: recargar);
    if (_datos == null) return const Cargando();
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final proximos = [
      ..._sinEnviar,
      ..._datos!.datos.where((e) => !e.fecha.isBefore(inicioHoy) && e.estado != 'CANCELADO'),
    ];
    final anteriores = _datos!.datos.where((e) => e.fecha.isBefore(inicioHoy) || e.estado == 'CANCELADO').toList();
    return Column(
      children: [
        if (_datos!.deCache) SinConexion(guardadoEn: _datos!.guardadoEn),
        Expanded(
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: widget.onNuevo,
                  icon: const Icon(Icons.add),
                  label: const Text('Hacer un encargo'),
                ),
                Titulo('Próximos'),
                if (proximos.isEmpty) const Text('No tienes encargos pendientes.', style: TextStyle(fontSize: 20)),
                for (final e in proximos)
                  _TarjetaEncargo(encargo: e, onCancelar: e.estado == 'PENDIENTE' ? () => _cancelar(e) : null),
                if (anteriores.isNotEmpty) ...[
                  Titulo('Anteriores'),
                  for (final e in anteriores.reversed) _TarjetaEncargo(encargo: e),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaEncargo extends StatelessWidget {
  final Encargo encargo;
  final VoidCallback? onCancelar;
  const _TarjetaEncargo({required this.encargo, this.onCancelar});

  @override
  Widget build(BuildContext context) {
    final e = encargo;
    final (String estado, Color color, IconData icono) = switch (e.estado) {
      'ENTREGADO' => ('Entregado', Tema.verde, Icons.check),
      'CANCELADO' => ('Cancelado', Tema.gris, Icons.close),
      'SIN_ENVIAR' => ('Se enviará al tener conexión', const Color(0xFF8A5A00), Icons.schedule_send),
      _ => ('Pendiente', const Color(0xFF0B4F8A), Icons.hourglass_bottom),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${cuando(e.fecha)} · ${e.tipoEtiqueta}', style: Theme.of(context).textTheme.titleSmall),
                ),
                Etiqueta(estado, color: color, icono: icono),
              ],
            ),
            const SizedBox(height: 6),
            Text(e.texto, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
            Text('${e.vendedor} · ${e.lugar}', style: Theme.of(context).textTheme.bodySmall),
            if (e.hechoPor != null) Text('Lo pidió ${e.hechoPor}', style: Theme.of(context).textTheme.bodySmall),
            if (onCancelar != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancelar,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
