import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Interruptores grandes para elegir de qué servicios recibir aviso en un pueblo (RF2).
class SuscripcionesView extends StatefulWidget {
  final Pueblo pueblo;
  final int? vecinoId;
  const SuscripcionesView({super.key, required this.pueblo, this.vecinoId});
  @override
  State<SuscripcionesView> createState() => _SuscripcionesViewState();
}

class _SuscripcionesViewState extends State<SuscripcionesView> {
  static const _servicios = [
    ('PAN', 'Pan'),
    ('PESCADO', 'Pescado'),
    ('FRUTA', 'Fruta y verdura'),
    ('CARNE', 'Carne'),
    ('MEDICO', 'Médico y avisos del ayuntamiento'),
  ];
  List<Suscripcion>? _subs;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(SuscripcionesView old) {
    super.didUpdateWidget(old);
    if (old.pueblo.id != widget.pueblo.id) _cargar();
  }

  Future<void> _cargar() async {
    try {
      final s = await Api.i.suscripciones(vecinoId: widget.vecinoId);
      if (mounted) {
        setState(() {
          _subs = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Suscripcion? _de(String tipo) {
    for (final s in _subs ?? <Suscripcion>[]) {
      if (s.tipo == tipo && s.pueblo.id == widget.pueblo.id) return s;
    }
    return null;
  }

  Future<void> _cambiar(String tipo, bool activar) async {
    try {
      if (activar) {
        await Api.i.post('/api/suscripciones', {
          'puebloId': widget.pueblo.id,
          'tipo': tipo,
          'minAntes': 15,
          'vecinoId': widget.vecinoId,
        });
      } else {
        await Api.i.delete('/api/suscripciones/${_de(tipo)!.id}');
      }
      await _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subs == null) {
      return _error != null ? ErrorReintentar(error: _error!, onReintentar: _cargar) : const Cargando();
    }
    return Card(
      child: Column(
        children: [
          for (final (tipo, nombre) in _servicios)
            SwitchListTile(
              secondary: Icon(Tema.icono(tipo), color: Tema.colorTipo(tipo), size: 32),
              title: Text(nombre, style: const TextStyle(fontSize: 20)),
              subtitle: Text(
                _de(tipo) == null ? 'Sin aviso' : (tipo == 'MEDICO' ? 'Avisar al momento' : 'Avisar 15 minutos antes'),
                style: const TextStyle(fontSize: 16),
              ),
              value: _de(tipo) != null,
              onChanged: (v) => _cambiar(tipo, v),
            ),
        ],
      ),
    );
  }
}
