import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/selector_pueblo.dart';

/// Pantalla del bar (RF13): solo lectura, letra muy grande, se actualiza sola cada 30 segundos.
/// Pensada para una tablet en modo quiosco: `/#/tablon/{id del pueblo}`
class TablonPage extends StatefulWidget {
  final int? puebloId;
  const TablonPage({super.key, this.puebloId});
  @override
  State<TablonPage> createState() => _TablonPageState();
}

class _TablonPageState extends State<TablonPage> {
  Hoy? _hoy;
  bool _sinRed = false;
  Timer? _timer;
  DateTime _ahora = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.puebloId != null) {
      _cargar();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _cargar());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.i.get('/api/public/tablon/${widget.puebloId}', autenticado: false);
      if (mounted) {
        setState(() {
          _hoy = Hoy.fromJson(r);
          _ahora = _hoy!.actualizado;
          _sinRed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _sinRed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.puebloId == null) return const _ElegirPueblo();
    const fondo = Color(0xFF0E1A17);
    return Scaffold(
      backgroundColor: fondo,
      body: _hoy == null
          ? const Center(child: CircularProgressIndicator(color: Tema.ambar))
          : LayoutBuilder(
              builder: (context, c) {
                final escala = (c.maxWidth / 1100).clamp(0.6, 1.6);
                double f(double x) => x * escala;
                final h = _hoy!;
                return Padding(
                  padding: EdgeInsets.all(f(36)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(f(10)),
                            decoration: BoxDecoration(color: Tema.ambar, borderRadius: BorderRadius.circular(f(16))),
                            child: Icon(Icons.campaign, size: f(44), color: Tema.tinta),
                          ),
                          SizedBox(width: f(18)),
                          Expanded(
                            child: Text(
                              'HOY EN ${h.pueblo.nombre.toUpperCase()}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: f(46),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            horaMinutos(_ahora),
                            style: TextStyle(color: Tema.ambar, fontSize: f(56), fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      SizedBox(height: f(8)),
                      Text(
                        '${fechaLarga(h.fecha)}${_sinRed ? ' · sin conexión, datos de las ${horaMinutos(h.actualizado)}' : ''}',
                        style: TextStyle(color: const Color(0xFFB8C7C2), fontSize: f(24)),
                      ),
                      SizedBox(height: f(24)),
                      for (final c in h.cambios)
                        _Franja(color: Tema.ambar, oscuro: true, icono: Icons.campaign, texto: c.resumen, f: f),
                      if (h.medico.estado == 'SIN_CONSULTA')
                        _Franja(
                          color: const Color(0xFFE5534B),
                          icono: Icons.event_busy,
                          texto: 'HOY NO HAY CONSULTA MÉDICA${h.medico.texto != null ? '. ${h.medico.texto}' : ''}',
                          f: f,
                        ),
                      if (h.medico.estado == 'CONSULTA')
                        _Franja(
                          color: const Color(0xFF7E57C2),
                          icono: Icons.medical_services,
                          texto: 'Consulta médica de ${hora(h.medico.horaInicio)} a ${hora(h.medico.horaFin)}',
                          f: f,
                        ),
                      SizedBox(height: f(12)),
                      Expanded(
                        child: h.pasos.isEmpty
                            ? Center(
                                child: Text(
                                  'Hoy no pasa ningún vendedor',
                                  style: TextStyle(color: Colors.white70, fontSize: f(40)),
                                ),
                              )
                            : ListView(
                                children: [for (final p in h.pasos) _FilaTablon(paso: p, f: f)],
                              ),
                      ),
                      Text(
                        'CLAXON · se actualiza solo',
                        style: TextStyle(color: const Color(0xFF8FA39D), fontSize: f(18)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Franja extends StatelessWidget {
  final Color color;
  final bool oscuro;
  final IconData icono;
  final String texto;
  final double Function(double) f;
  const _Franja({required this.color, required this.icono, required this.texto, required this.f, this.oscuro = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: f(12)),
    padding: EdgeInsets.symmetric(horizontal: f(22), vertical: f(16)),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(f(18))),
    child: Row(
      children: [
        Icon(icono, size: f(40), color: oscuro ? Tema.tinta : Colors.white),
        SizedBox(width: f(16)),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: f(32), fontWeight: FontWeight.w800, color: oscuro ? Tema.tinta : Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _FilaTablon extends StatelessWidget {
  final Paso paso;
  final double Function(double) f;
  const _FilaTablon({required this.paso, required this.f});
  @override
  Widget build(BuildContext context) {
    final hecho = paso.estado == 'LLEGADO' || paso.estado == 'SIN_SERVICIO_HOY';
    final pronto = paso.minutosFaltan != null && paso.minutosFaltan! <= 15 && paso.estado == 'EN_CAMINO';
    final estado = switch (paso.estado) {
      'LLEGADO' => 'Ya ha pasado',
      'SIN_SERVICIO_HOY' => 'Terminado',
      'EN_CAMINO' => paso.minutosFaltan != null ? 'Llega en ${paso.minutosFaltan} min' : 'En camino',
      _ => paso.minutosFaltan == null ? 'Aún no ha salido' : 'Previsto',
    };
    return Container(
      margin: EdgeInsets.only(bottom: f(14)),
      padding: EdgeInsets.all(f(22)),
      decoration: BoxDecoration(
        color: pronto ? const Color(0xFF1F4D3F) : const Color(0xFF16261F),
        borderRadius: BorderRadius.circular(f(20)),
        border: Border.all(color: pronto ? Tema.ambar : const Color(0xFF2B3F38), width: pronto ? 4 : 2),
      ),
      child: Row(
        children: [
          Icon(Tema.icono(paso.tipo), size: f(60), color: hecho ? Colors.white38 : Colors.white),
          SizedBox(width: f(22)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.tipoEtiqueta.toUpperCase(),
                  style: TextStyle(
                    color: hecho ? Colors.white38 : Colors.white,
                    fontSize: f(40),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${paso.vendedor} · ${paso.lugar}',
                  style: TextStyle(color: hecho ? Colors.white38 : const Color(0xFFCFDAD6), fontSize: f(24)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hora(paso.hora),
                style: TextStyle(
                  color: hecho ? Colors.white38 : Colors.white,
                  fontSize: f(64),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                estado,
                style: TextStyle(
                  color: pronto ? Tema.ambar : (hecho ? Colors.white38 : const Color(0xFFCFDAD6)),
                  fontSize: f(26),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElegirPueblo extends StatefulWidget {
  const _ElegirPueblo();
  @override
  State<_ElegirPueblo> createState() => _ElegirPuebloState();
}

class _ElegirPuebloState extends State<_ElegirPueblo> {
  Pueblo? _pueblo;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pantalla del bar')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elige el pueblo que mostrará esta pantalla.', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              SelectorPueblo(pueblo: _pueblo, onElegido: (p) => setState(() => _pueblo = p)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _pueblo == null
                    ? null
                    : () => Navigator.pushReplacementNamed(context, '/tablon/${_pueblo!.id}'),
                child: const Text('Abrir tablón'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
