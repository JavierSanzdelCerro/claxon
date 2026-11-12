import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import 'ruta_editor_page.dart';

/// Alta y modificación de rutas (RF10).
class MisRutasTab extends StatefulWidget {
  const MisRutasTab({super.key});
  @override
  State<MisRutasTab> createState() => _MisRutasTabState();
}

class _MisRutasTabState extends State<MisRutasTab> {
  List<Ruta>? _rutas;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.i.get('/api/vendedor/rutas') as List;
      if (mounted) {
        setState(() {
          _rutas = r.map((e) => Ruta.fromJson(e)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _abrir([Ruta? ruta]) async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RutaEditorPage(ruta: ruta)));
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_rutas == null) {
      return _error != null ? ErrorReintentar(error: _error!, onReintentar: _cargar) : const Cargando();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(onPressed: () => _abrir(), icon: const Icon(Icons.add), label: const Text('Nueva ruta')),
        const SizedBox(height: 8),
        for (final r in _rutas!)
          Card(
            child: ListTile(
              minTileHeight: 80,
              title: Text(
                r.nombre + (r.activa ? '' : ' (desactivada)'),
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${describirDias(r.diasSemana)}${r.horaSalidaHabitual != null ? ' · sale a las ${hora(r.horaSalidaHabitual)}' : ''}\n'
                '${r.paradas.map((p) => p.pueblo.nombre).join(' → ')}',
                style: const TextStyle(fontSize: 17),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.edit),
              onTap: () => _abrir(r),
            ),
          ),
      ],
    );
  }
}
