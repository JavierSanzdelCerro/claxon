import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Encargos agrupados por parada, para llevarlos preparados (RF9, HU3).
class EncargosVendedorTab extends StatefulWidget {
  const EncargosVendedorTab({super.key});
  @override
  State<EncargosVendedorTab> createState() => EncargosVendedorTabState();
}

class EncargosVendedorTabState extends State<EncargosVendedorTab> {
  List<RutaHoy>? _rutas;
  int? _rutaId;
  DateTime _dia = DateTime.now();
  Guardado<List<dynamic>>? _datos;
  Object? _error;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      if (_rutas == null) {
        final r = await Api.i.guardando<List<dynamic>>('/api/vendedor/hoy');
        _rutas = r.datos.map((e) => RutaHoy.fromJson(e)).toList();
        _rutaId ??= _rutas!.isEmpty ? null : _rutas!.first.rutaId;
      }
      if (_rutaId == null) {
        if (mounted) setState(() => _datos = Guardado([], false, DateTime.now()));
        return;
      }
      final d = await Api.i.guardando<List<dynamic>>('/api/vendedor/rutas/$_rutaId/encargos?fecha=${isoFecha(_dia)}');
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

  Future<void> _marcar(Encargo e, bool entregado) async {
    try {
      await Api.i.post('/api/vendedor/encargos/${e.id}/entregado?valor=$entregado');
      await recargar();
    } catch (err) {
      if (mounted) mostrarError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_datos == null && _error != null) return ErrorReintentar(error: _error!, onReintentar: recargar);
    if (_datos == null) return const Cargando();
    final grupos = _datos!.datos.map((e) => EncargosParada.fromJson(e)).toList();
    final total = grupos.fold<int>(0, (s, g) => s + g.encargos.length);
    final hoy = DateTime.now();
    return Column(
      children: [
        if (_datos!.deCache) SinConexion(guardadoEn: _datos!.guardadoEn),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(cuando(hoy.add(Duration(days: i)))),
                  selected: mismoDia(_dia, hoy.add(Duration(days: i))),
                  onSelected: (_) {
                    setState(() => _dia = hoy.add(Duration(days: i)));
                    recargar();
                  },
                ),
              if ((_rutas?.length ?? 0) > 1)
                for (final r in _rutas!)
                  ChoiceChip(
                    label: Text(r.nombre),
                    selected: r.rutaId == _rutaId,
                    onSelected: (_) {
                      setState(() => _rutaId = r.rutaId);
                      recargar();
                    },
                  ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '$total encargos para ${cuando(_dia).toLowerCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final g in grupos)
                  if (g.encargos.isNotEmpty) ...[
                    Titulo('${g.orden}. ${g.pueblo} · ${g.lugar} · ${hora(g.hora)}'),
                    for (final e in g.encargos)
                      Card(
                        color: e.estado == 'ENTREGADO' ? const Color(0xFFEAF5EF) : null,
                        child: CheckboxListTile(
                          value: e.estado == 'ENTREGADO',
                          onChanged: (v) => _marcar(e, v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            e.texto,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              decoration: e.estado == 'ENTREGADO' ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            '${e.vecino}${e.telefonoVecino != null ? ' · ${e.telefonoVecino}' : ''}${e.hechoPor != null ? ' · lo pidió ${e.hechoPor}' : ''}',
                            style: const TextStyle(fontSize: 17),
                          ),
                          secondary: e.estado == 'ENTREGADO' ? const Etiqueta('Entregado', color: Tema.verde) : null,
                        ),
                      ),
                  ],
                if (total == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('No hay encargos para este día.', style: TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
