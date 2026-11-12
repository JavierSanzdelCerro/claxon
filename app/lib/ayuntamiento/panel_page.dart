import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';
import '../widgets/hoy_view.dart';

/// Panel web del ayuntamiento (HU5): publicar días de médico y cambios, que llegan al momento.
class PanelPage extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onSalir;
  const PanelPage({super.key, required this.usuario, required this.onSalir});
  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  Panel? _panel;
  Object? _error;

  String _tipo = 'SIN_CONSULTA';
  DateTime _fecha = DateTime.now();
  TimeOfDay _inicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 11, minute: 0);
  final _texto = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = Panel.fromJson(await Api.i.get('/api/ayuntamiento/panel'));
      if (mounted) {
        setState(() {
          _panel = p;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String _hm(TimeOfDay t) => '${dosCifras(t.hour)}:${dosCifras(t.minute)}';

  Future<void> _publicar() async {
    setState(() => _enviando = true);
    try {
      final r = await Api.i.post('/api/ayuntamiento/avisos', {
        'tipo': _tipo,
        'fecha': isoFecha(_fecha),
        if (_tipo == 'CONSULTA') 'horaInicio': _hm(_inicio),
        if (_tipo == 'CONSULTA') 'horaFin': _hm(_fin),
        'texto': _texto.text.trim().isEmpty ? null : _texto.text.trim(),
      });
      _texto.clear();
      await _cargar();
      if (mounted) mostrarMensaje(context, 'Aviso publicado y enviado a ${r['avisados']} personas');
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _borrar(Aviso a) async {
    if (!await confirmar(context, '¿Borrar «${a.resumen}»? (los avisos ya enviados no se retiran)')) return;
    try {
      await Api.i.delete('/api/ayuntamiento/avisos/${a.id}');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pueblo = widget.usuario.pueblo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayuntamiento de ${pueblo?.nombre ?? ''}'),
        actions: [
          if (pueblo != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/tablon/${pueblo.id}'),
              icon: const Icon(Icons.tv),
              label: const Text('Pantalla del bar'),
            ),
          IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onSalir, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _panel == null
          ? (_error != null ? ErrorReintentar(error: _error!, onReintentar: _cargar) : const Cargando())
          : LayoutBuilder(
              builder: (context, c) {
                final ancho = c.maxWidth > 900;
                final formulario = _formulario();
                final vista = _vistaHoy();
                return ancho
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 460, child: formulario),
                          const VerticalDivider(width: 1),
                          Expanded(child: vista),
                        ],
                      )
                    : ListView(
                        children: [
                          formulario,
                          SizedBox(height: 900, child: vista),
                        ],
                      );
              },
            ),
    );
  }

  Widget _formulario() {
    final p = _panel!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Tema.verde,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    '${p.vecinosSuscritos} vecinos suscritos',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Titulo('Publicar aviso'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'SIN_CONSULTA', label: Text('Sin consulta')),
              ButtonSegment(value: 'CONSULTA', label: Text('Consulta')),
              ButtonSegment(value: 'CAMBIO', label: Text('Otro aviso')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text('${cuando(_fecha)} · ${fechaLarga(_fecha)}'),
            onPressed: () async {
              final hoy = DateTime.now();
              final f = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime(hoy.year, hoy.month, hoy.day),
                lastDate: hoy.add(const Duration(days: 90)),
              );
              if (f != null) setState(() => _fecha = f);
            },
          ),
          if (_tipo == 'CONSULTA') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _inicio);
                      if (t != null) setState(() => _inicio = t);
                    },
                    child: Text('De ${_inicio.hour}:${dosCifras(_inicio.minute)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _fin);
                      if (t != null) setState(() => _fin = t);
                    },
                    child: Text('a ${_fin.hour}:${dosCifras(_fin.minute)}'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _texto,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: _tipo == 'CAMBIO' ? 'Mensaje' : 'Mensaje (opcional)',
              hintText: _tipo == 'SIN_CONSULTA' ? 'Por ejemplo: Centro de salud de Utrillas.' : null,
            ),
          ),
          FilledButton.icon(
            onPressed: _enviando ? null : _publicar,
            icon: const Icon(Icons.send),
            label: const Text('Enviar aviso'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Se envía al momento a los vecinos suscritos, a sus familiares y a la pantalla del bar.',
            style: TextStyle(fontSize: 16, color: Tema.gris),
          ),
          Titulo('Próximos avisos'),
          if (p.proximos.isEmpty) const Text('No hay avisos publicados.'),
          for (final a in p.proximos)
            Card(
              child: ListTile(
                leading: Icon(
                  a.tipo == 'SIN_CONSULTA'
                      ? Icons.event_busy
                      : (a.tipo == 'CONSULTA' ? Icons.medical_services : Icons.campaign),
                  color: a.tipo == 'SIN_CONSULTA' ? Tema.rojo : Tema.verde,
                ),
                title: Text(a.resumen, style: const TextStyle(fontSize: 17)),
                trailing: IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _borrar(a),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vistaHoy() => HoyView(
    hoy: _panel!.hoy,
    deCache: false,
    guardadoEn: DateTime.now(),
    onRefrescar: _cargar,
    titulo: 'Así lo ven hoy los vecinos',
  );
}
