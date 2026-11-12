import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../vecino/avisos_tab.dart';
import '../vecino/encargo_page.dart';
import '../vecino/encargos_tab.dart';
import '../vecino/hoy_tab.dart';
import '../vecino/suscripciones_view.dart';

/// Lo que ve el familiar de una persona vinculada: su «Hoy», sus encargos, sus avisos y sus ajustes.
class VecinoDetallePage extends StatefulWidget {
  final VecinoVinculado vecino;
  const VecinoDetallePage({super.key, required this.vecino});
  @override
  State<VecinoDetallePage> createState() => _VecinoDetallePageState();
}

class _VecinoDetallePageState extends State<VecinoDetallePage> {
  final _encargos = GlobalKey<EncargosTabState>();

  Future<void> _encargar() async {
    final v = widget.vecino;
    if (v.pueblo == null) return;
    final hecho = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EncargoPage(puebloId: v.pueblo!.id, vecinoId: v.id, paraQuien: v.nombre),
      ),
    );
    if (hecho == true) _encargos.currentState?.recargar();
  }

  Future<void> _desvincular() async {
    if (!await confirmar(context, '¿Dejar de seguir a ${widget.vecino.nombre}?')) return;
    try {
      await Api.i.delete('/api/familia/vecinos/${widget.vecino.id}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vecino;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Avisos de ${v.nombre.split(' ').first}'),
          actions: [IconButton(tooltip: 'Desvincular', onPressed: _desvincular, icon: const Icon(Icons.link_off))],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFD7EDE7),
            indicatorColor: Color(0xFFF2A900),
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Hoy'),
              Tab(text: 'Encargos'),
              Tab(text: 'Avisos'),
              Tab(text: 'Ajustes'),
            ],
          ),
        ),
        body: v.pueblo == null
            ? const Center(child: Text('Esta persona no tiene pueblo configurado.'))
            : TabBarView(
                children: [
                  HoyTab(
                    puebloId: v.pueblo!.id,
                    titulo: 'Hoy en ${v.pueblo!.nombre}',
                    onEncargar: v.puedeEncargar ? _encargar : null,
                  ),
                  EncargosTab(key: _encargos, vecinoId: v.id, onNuevo: _encargar),
                  AvisosTab(vecinoId: v.id),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Titulo('Avisos que recibe ${v.nombre.split(' ').first}'),
                      SuscripcionesView(pueblo: v.pueblo!, vecinoId: v.id),
                      const SizedBox(height: 12),
                      const Text('Tú recibirás una copia de cada aviso.', style: TextStyle(fontSize: 17)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
