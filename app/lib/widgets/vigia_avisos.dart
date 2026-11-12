import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/modelos.dart';
import '../core/tema.dart';

/// Vigila los avisos nuevos mientras la app está abierta y los muestra en grande.
/// Con Firebase configurado, además llegan como notificación del sistema aunque la app esté cerrada.
/// También reenvía los encargos que se quedaron en cola sin conexión (RF15).
class VigiaAvisos extends StatefulWidget {
  final Widget child;
  final VoidCallback? onNuevos;
  const VigiaAvisos({super.key, required this.child, this.onNuevos});

  @override
  State<VigiaAvisos> createState() => _VigiaAvisosState();
}

class _VigiaAvisosState extends State<VigiaAvisos> {
  Timer? _timer;
  DateTime? _desde;
  final Set<int> _mostrados = {};

  @override
  void initState() {
    super.initState();
    _primeraVez();
    _timer = Timer.periodic(Config.intervaloSondeo, (_) => _revisar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _primeraVez() async {
    try {
      // No se repiten como emergentes los avisos de antes de abrir la app, salvo los no vistos de los últimos 20 min.
      final lista = await Api.i.notificaciones();
      final ahora = lista.isEmpty ? null : lista.first.enviadaEn;
      for (final n in lista) {
        _mostrados.add(n.id);
      }
      _desde = ahora;
      final recientes = lista
          .where(
            (n) =>
                n.vistaEn == null &&
                n.paraVecino == null &&
                ahora != null &&
                ahora.difference(n.enviadaEn).inMinutes < 20,
          )
          .toList();
      if (recientes.isNotEmpty && mounted) _mostrar(recientes.first);
    } catch (_) {}
    _revisar();
  }

  Future<void> _revisar() async {
    final enviados = await Api.i.vaciarCola();
    if (enviados > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enviados == 1 ? 'Se ha enviado tu encargo pendiente' : 'Se han enviado $enviados encargos pendientes',
          ),
          backgroundColor: Tema.verde,
        ),
      );
      widget.onNuevos?.call();
    }
    try {
      final nuevas = await Api.i.notificaciones(desde: _desde);
      final sinMostrar = nuevas.where((n) => !_mostrados.contains(n.id)).toList();
      if (nuevas.isNotEmpty) _desde = nuevas.first.enviadaEn.subtract(const Duration(seconds: 1));
      if (sinMostrar.isEmpty || !mounted) return;
      for (final n in sinMostrar) {
        _mostrados.add(n.id);
      }
      widget.onNuevos?.call();
      // Si llegan varios a la vez, se muestra el más reciente.
      _mostrar(sinMostrar.first);
    } catch (_) {
      // Sin conexión: se intentará en la siguiente vuelta.
    }
  }

  void _mostrar(Notificacion n) {
    final vista = View.of(context);
    SemanticsService.sendAnnouncement(vista, '${n.titulo}. ${n.texto}', TextDirection.ltr);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(n.tipo == 'AYUNTAMIENTO' ? Icons.campaign : Icons.notifications_active, size: 48, color: Tema.verde),
        title: Text(
          n.titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        content: Text(n.texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              if (n.paraVecino == null) Api.i.post('/api/notificaciones/${n.id}/vista').catchError((_) => null);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
