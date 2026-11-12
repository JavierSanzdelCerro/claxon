import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_pueblo.dart';

class RutaEditorPage extends StatefulWidget {
  final Ruta? ruta;
  const RutaEditorPage({super.key, this.ruta});
  @override
  State<RutaEditorPage> createState() => _RutaEditorPageState();
}

class _ParadaEditable {
  int? id;
  Pueblo? pueblo;
  final TextEditingController lugar;
  final TextEditingController minutos;
  _ParadaEditable({this.id, this.pueblo, String lugar = 'Plaza', int minutos = 0})
    : lugar = TextEditingController(text: lugar),
      minutos = TextEditingController(text: '$minutos');
}

class _RutaEditorPageState extends State<RutaEditorPage> {
  late final TextEditingController _nombre;
  late Set<int> _dias;
  TimeOfDay? _salida;
  bool _activa = true;
  late List<_ParadaEditable> _paradas;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final r = widget.ruta;
    _nombre = TextEditingController(text: r?.nombre ?? '');
    _dias = r == null ? {1, 2, 3, 4, 5, 6} : r.diasSemana.split(',').map(int.parse).toSet();
    if (r?.horaSalidaHabitual != null) {
      final p = r!.horaSalidaHabitual!.split(':');
      _salida = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } else {
      _salida = const TimeOfDay(hour: 9, minute: 0);
    }
    _activa = r?.activa ?? true;
    _paradas = r == null
        ? [_ParadaEditable()]
        : r.paradas
              .map((p) => _ParadaEditable(id: p.id, pueblo: p.pueblo, lugar: p.lugar, minutos: p.minDesdeSalida))
              .toList();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _dias.isEmpty || _paradas.any((p) => p.pueblo == null)) {
      mostrarMensaje(context, 'Pon un nombre, al menos un día y el pueblo de cada parada', error: true);
      return;
    }
    final cuerpo = {
      'nombre': _nombre.text.trim(),
      'diasSemana': (_dias.toList()..sort()).join(','),
      'horaSalidaHabitual': _salida == null ? null : '${dosCifras(_salida!.hour)}:${dosCifras(_salida!.minute)}',
      'activa': _activa,
      'paradas': [
        for (final p in _paradas)
          {
            'id': p.id,
            'puebloId': p.pueblo!.id,
            'lugar': p.lugar.text.trim().isEmpty ? 'Plaza' : p.lugar.text.trim(),
            'minDesdeSalida': int.tryParse(p.minutos.text) ?? 0,
          },
      ],
    };
    setState(() => _guardando = true);
    try {
      if (widget.ruta == null) {
        await Api.i.post('/api/vendedor/rutas', cuerpo);
      } else {
        await Api.i.put('/api/vendedor/rutas/${widget.ruta!.id}', cuerpo);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrar() async {
    if (!await confirmar(context, '¿Borrar esta ruta? Si ya tiene días hechos o encargos, se desactivará.')) return;
    try {
      await Api.i.delete('/api/vendedor/rutas/${widget.ruta!.id}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruta == null ? 'Nueva ruta' : 'Editar ruta'),
        actions: [
          if (widget.ruta != null) IconButton(tooltip: 'Borrar', onPressed: _borrar, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre de la ruta'),
              ),
              Titulo('Días'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(diaCorto(d), style: const TextStyle(fontSize: 18)),
                      selected: _dias.contains(d),
                      onSelected: (v) => setState(() => v ? _dias.add(d) : _dias.remove(d)),
                    ),
                ],
              ),
              Titulo('Hora de salida habitual'),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_salida == null ? 'Elegir' : '${_salida!.hour}:${dosCifras(_salida!.minute)}'),
                onPressed: () async {
                  final h = await showTimePicker(
                    context: context,
                    initialTime: _salida ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (h != null) setState(() => _salida = h);
                },
              ),
              SwitchListTile(
                title: const Text('Ruta activa', style: TextStyle(fontSize: 19)),
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),
              Titulo('Paradas (en orden)'),
              for (var i = 0; i < _paradas.length; i++) _filaParada(i),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  final ultimo = _paradas.isEmpty ? 0 : (int.tryParse(_paradas.last.minutos.text) ?? 0);
                  _paradas.add(_ParadaEditable(minutos: ultimo + 20));
                }),
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Añadir parada'),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar ruta')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaParada(int i) {
    final p = _paradas[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${i + 1}')),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectorPueblo(pueblo: p.pueblo, onElegido: (x) => setState(() => p.pueblo = x)),
                ),
                IconButton(
                  tooltip: 'Subir',
                  onPressed: i == 0 ? null : () => setState(() => _paradas.insert(i - 1, _paradas.removeAt(i))),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: _paradas.length == 1 ? null : () => setState(() => _paradas.removeAt(i)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: p.lugar,
                    decoration: const InputDecoration(labelText: 'Sitio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: p.minutos,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min. desde salida'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
