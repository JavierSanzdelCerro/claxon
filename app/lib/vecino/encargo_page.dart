import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Hacer un encargo en tres toques (RNF2): vendedor → día → qué quieres.
/// Si no hay conexión se guarda y se envía solo al recuperarla (RF15).
class EncargoPage extends StatefulWidget {
  final int puebloId;
  final int? vecinoId;
  final String? paraQuien;
  const EncargoPage({super.key, required this.puebloId, this.vecinoId, this.paraQuien});
  @override
  State<EncargoPage> createState() => _EncargoPageState();
}

class _EncargoPageState extends State<EncargoPage> {
  List<ParadaEncargable>? _paradas;
  Object? _error;
  ParadaEncargable? _parada;
  DateTime? _dia;
  final _texto = TextEditingController();
  bool _enviando = false;

  static const _sugerencias = {
    'PAN': ['1 barra', '2 barras', '1 hogaza', '6 magdalenas', '1 bizcocho'],
    'PESCADO': ['1 kg de sardinas', '1/2 kg de merluza', '1 dorada', '2 truchas'],
    'FRUTA': ['1 kg de manzanas', '1 kg de naranjas', '1 lechuga', '1 kg de tomates'],
    'CARNE': ['1/2 kg de filetes', '1 pollo', '1/2 kg de chorizo'],
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = await Api.i.paradasDe(widget.puebloId);
      if (!mounted) return;
      setState(() {
        _paradas = p;
        _error = null;
        if (p.length == 1) _elegirParada(p.first);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _elegirParada(ParadaEncargable p) {
    _parada = p;
    _dia = p.proximosDias.isEmpty ? null : p.proximosDias.first;
  }

  void _anadir(String s) {
    final actual = _texto.text.trim();
    _texto.text = actual.isEmpty ? s : '$actual, $s';
    setState(() {});
  }

  Future<void> _enviar() async {
    if (_parada == null || _dia == null || _texto.text.trim().isEmpty) return;
    final peticion = {
      'paradaId': _parada!.paradaId,
      'fecha': isoFecha(_dia!),
      'texto': _texto.text.trim(),
      'vecinoId': widget.vecinoId,
      'idCliente': Api.nuevoIdCliente(),
    };
    setState(() => _enviando = true);
    try {
      await Api.i.post('/api/encargos', peticion);
      if (!mounted) return;
      mostrarMensaje(context, 'Encargo hecho. ${_parada!.vendedor} lo llevará preparado.');
      Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (e.sinConexion) {
        await Api.i.encolarEncargo(peticion, {
          'lugar': _parada!.lugar,
          'vendedor': _parada!.vendedor,
          'tipoEtiqueta': _parada!.tipoEtiqueta,
        });
        if (!mounted) return;
        mostrarMensaje(context, 'No hay conexión. Tu encargo se enviará solo cuando vuelva la cobertura.');
        Navigator.pop(context, true);
      } else if (mounted) {
        mostrarError(context, e);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.paraQuien == null ? 'Hacer un encargo' : 'Encargo para ${widget.paraQuien}')),
      body: _paradas == null
          ? (_error != null ? ErrorReintentar(error: _error!, onReintentar: _cargar) : const Cargando())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Titulo('1. ¿A quién?'),
                    if (_paradas!.isEmpty)
                      const Text('Ningún vendedor pasa por este pueblo.', style: TextStyle(fontSize: 20)),
                    for (final p in _paradas!)
                      Card(
                        color: _parada == p ? Tema.ambar.withValues(alpha: 0.25) : null,
                        child: ListTile(
                          minTileHeight: 72,
                          leading: Icon(Tema.icono(p.tipo), size: 36, color: Tema.colorTipo(p.tipo)),
                          title: Text('${p.tipoEtiqueta} · ${p.vendedor}', style: t.titleSmall),
                          subtitle: Text(
                            '${p.lugar}${p.horaHabitual != null ? ' · hacia las ${hora(p.horaHabitual)}' : ''}',
                            style: t.bodyMedium,
                          ),
                          trailing: _parada == p ? const Icon(Icons.check_circle, color: Tema.verde, size: 32) : null,
                          onTap: () => setState(() => _elegirParada(p)),
                        ),
                      ),
                    if (_parada != null) ...[
                      Titulo('2. ¿Qué día?'),
                      if (_parada!.proximosDias.isEmpty)
                        const Text('No hay días próximos.', style: TextStyle(fontSize: 20)),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final d in _parada!.proximosDias)
                            ChoiceChip(
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: Text(cuando(d), style: const TextStyle(fontSize: 19)),
                              ),
                              selected: _dia != null && mismoDia(_dia!, d),
                              onSelected: (_) => setState(() => _dia = d),
                            ),
                        ],
                      ),
                      Titulo('3. ¿Qué quieres?'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _sugerencias[_parada!.tipo] ?? const <String>[])
                            ActionChip(
                              avatar: const Icon(Icons.add),
                              label: Text(s, style: const TextStyle(fontSize: 18)),
                              onPressed: () => _anadir(s),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _texto,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 20),
                        decoration: const InputDecoration(labelText: 'Escribe o toca arriba'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _enviando || _dia == null || _texto.text.trim().isEmpty ? null : _enviar,
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar encargo'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
