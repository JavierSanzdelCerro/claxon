import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Historial de avisos recibidos.
class AvisosTab extends StatefulWidget {
  /// Si se indica, muestra los avisos de ese vecino (vista del familiar, con «lo vio a las…»).
  final int? vecinoId;
  const AvisosTab({super.key, this.vecinoId});
  @override
  State<AvisosTab> createState() => AvisosTabState();
}

class AvisosTabState extends State<AvisosTab> {
  List<Notificacion>? _lista;
  Object? _error;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      final List<Notificacion> l;
      if (widget.vecinoId != null) {
        final r = await Api.i.get('/api/familia/vecinos/${widget.vecinoId}/avisos') as List;
        l = r.map((e) => Notificacion.fromJson(e)).toList();
      } else {
        l = await Api.i.notificaciones();
        // Abrir esta pestaña cuenta como haber visto los avisos (HU9).
        for (final n in l.where((n) => n.vistaEn == null && n.paraVecino == null)) {
          Api.i.post('/api/notificaciones/${n.id}/vista').catchError((_) => null);
        }
      }
      if (mounted) {
        setState(() {
          _lista = l;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lista == null && _error != null) return ErrorReintentar(error: _error!, onReintentar: recargar);
    if (_lista == null) return const Cargando();
    return RefreshIndicator(
      onRefresh: recargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_lista!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Todavía no hay avisos. Te avisaremos 15 minutos antes de que llegue cada vendedor.',
                style: TextStyle(fontSize: 20),
              ),
            ),
          for (final n in _lista!)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      switch (n.tipo) {
                        'AYUNTAMIENTO' => Icons.campaign,
                        'CORRECCION' => Icons.update,
                        _ => Icons.notifications_active,
                      },
                      size: 32,
                      color: n.tipo == 'CORRECCION' ? Tema.rojo : Tema.verde,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.titulo, style: Theme.of(context).textTheme.titleSmall),
                          Text(n.texto, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${cuando(n.enviadaEn)} a las ${horaMinutos(n.enviadaEn)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (widget.vecinoId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: n.vistaEn != null
                                  ? Etiqueta(
                                      'Lo vio a las ${horaMinutos(n.vistaEn!)}',
                                      color: Tema.verde,
                                      icono: Icons.visibility,
                                    )
                                  : const Etiqueta('Aún no lo ha visto', color: Tema.gris, icono: Icons.visibility_off),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
