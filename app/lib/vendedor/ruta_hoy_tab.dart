import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// «Iniciar ruta» (RF7) y «He llegado» (RF8) con un único botón grande.
class RutaHoyTab extends StatefulWidget {
  final VoidCallback onVerEncargos;
  const RutaHoyTab({super.key, required this.onVerEncargos});
  @override
  State<RutaHoyTab> createState() => RutaHoyTabState();
}

class RutaHoyTabState extends State<RutaHoyTab> {
  Guardado<List<dynamic>>? _datos;
  Object? _error;
  int? _elegida;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      final d = await Api.i.guardando<List<dynamic>>('/api/vendedor/hoy');
      if (mounted) {
        setState(() {
          _datos = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _accion(String ruta, String ok) async {
    setState(() => _ocupado = true);
    try {
      await Api.i.post(ruta);
      await recargar();
      if (mounted) mostrarMensaje(context, ok);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_datos == null && _error != null) return ErrorReintentar(error: _error!, onReintentar: recargar);
    if (_datos == null) return const Cargando();
    final rutas = _datos!.datos.map((e) => RutaHoy.fromJson(e)).toList();
    if (rutas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes rutas. Créala en «Mis rutas».',
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final ruta = rutas.firstWhere((r) => r.rutaId == _elegida, orElse: () => rutas.first);
    final t = Theme.of(context).textTheme;
    final siguiente = ruta.siguiente;
    final pendientes = ruta.paradas.fold<int>(0, (s, p) => s + p.encargosPendientes);

    return Column(
      children: [
        if (_datos!.deCache) SinConexion(guardadoEn: _datos!.guardadoEn),
        Expanded(
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (rutas.length > 1)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in rutas)
                        ChoiceChip(
                          label: Text(r.nombre + (r.tocaHoy ? '' : ' (hoy no toca)')),
                          selected: r.rutaId == ruta.rutaId,
                          onSelected: (_) => setState(() => _elegida = r.rutaId),
                        ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text('Ruta de hoy · ${ruta.nombre}', style: t.titleLarge),
                Text(switch (ruta.estadoJornada) {
                  'EN_RUTA' =>
                    'Saliste a las ${hora(ruta.horaInicio)}'
                        '${ruta.retrasoMin > 0
                            ? ' · vas ${ruta.retrasoMin} min tarde'
                            : ruta.retrasoMin < 0
                            ? ' · vas ${-ruta.retrasoMin} min adelantado'
                            : ''}',
                  'TERMINADA' => 'Ruta terminada. ¡Buen trabajo!',
                  _ =>
                    ruta.horaSalidaHabitual != null
                        ? 'Salida habitual a las ${hora(ruta.horaSalidaHabitual)}'
                        : 'Sin hora habitual',
                }, style: t.bodyLarge),
                if (pendientes > 0)
                  TextButton.icon(
                    onPressed: widget.onVerEncargos,
                    icon: const Icon(Icons.inventory_2),
                    label: Text('$pendientes encargos por entregar'),
                  ),
                const SizedBox(height: 12),
                _BotonGrande(
                  ruta: ruta,
                  siguiente: siguiente,
                  ocupado: _ocupado,
                  onIniciar: () => _accion(
                    '/api/vendedor/rutas/${ruta.rutaId}/iniciar',
                    'Ruta iniciada. Los vecinos recibirán el aviso.',
                  ),
                  onLlegado: () => _accion(
                    '/api/vendedor/rutas/${ruta.rutaId}/llegado',
                    'Llegada a ${siguiente?.pueblo} registrada',
                  ),
                ),
                const SizedBox(height: 16),
                for (final p in ruta.paradas) _FilaParada(parada: p, esSiguiente: p == siguiente),
                if (ruta.estadoJornada == 'EN_RUTA') ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _ocupado
                        ? null
                        : () async {
                            if (await confirmar(context, '¿Terminar la ruta de hoy? No se mandarán más avisos.')) {
                              _accion('/api/vendedor/rutas/${ruta.rutaId}/terminar', 'Ruta terminada');
                            }
                          },
                    child: const Text('Terminar ruta'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonGrande extends StatelessWidget {
  final RutaHoy ruta;
  final ParadaHoy? siguiente;
  final bool ocupado;
  final VoidCallback onIniciar;
  final VoidCallback onLlegado;
  const _BotonGrande({
    required this.ruta,
    required this.siguiente,
    required this.ocupado,
    required this.onIniciar,
    required this.onLlegado,
  });

  @override
  Widget build(BuildContext context) {
    if (ruta.estadoJornada == 'TERMINADA') return const SizedBox.shrink();
    final iniciar = ruta.estadoJornada == 'PREVISTA';
    return SizedBox(
      height: 120,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: iniciar ? Tema.verde : Tema.ambar,
          foregroundColor: iniciar ? Colors.white : Tema.tinta,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: ocupado ? null : (iniciar ? onIniciar : onLlegado),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iniciar ? Icons.play_arrow : Icons.where_to_vote, size: 44),
                const SizedBox(width: 10),
                Text(
                  iniciar ? 'Iniciar ruta' : 'He llegado',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (!iniciar && siguiente != null)
              Text('a ${siguiente!.pueblo} · ${siguiente!.lugar}', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _FilaParada extends StatelessWidget {
  final ParadaHoy parada;
  final bool esSiguiente;
  const _FilaParada({required this.parada, required this.esSiguiente});

  @override
  Widget build(BuildContext context) {
    final p = parada;
    final hecho = p.estado == 'LLEGADO';
    return Card(
      color: esSiguiente ? Tema.ambar.withValues(alpha: 0.2) : (hecho ? const Color(0xFFF0F0F0) : null),
      child: ListTile(
        minTileHeight: 72,
        leading: CircleAvatar(
          backgroundColor: hecho ? Tema.gris : Tema.verde,
          foregroundColor: Colors.white,
          child: hecho ? const Icon(Icons.check) : Text('${p.orden}', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(p.pueblo, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${p.lugar} · ${p.encargosTotales == 0 ? 'sin encargos' : '${p.encargosPendientes} de ${p.encargosTotales} encargos por entregar'}',
          style: const TextStyle(fontSize: 17),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(hora(p.hora), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            Text(hecho ? 'hecho' : (esSiguiente ? 'siguiente' : 'previsto'), style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
