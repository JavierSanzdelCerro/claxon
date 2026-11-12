import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../widgets/hoy_view.dart';

/// Pestaña «Hoy» del vecino (o del familiar, viendo el pueblo de su madre).
class HoyTab extends StatefulWidget {
  final int puebloId;
  final String? titulo;
  final VoidCallback? onEncargar;
  const HoyTab({super.key, required this.puebloId, this.onEncargar, this.titulo});
  @override
  State<HoyTab> createState() => HoyTabState();
}

class HoyTabState extends State<HoyTab> {
  Guardado<Hoy>? _hoy;
  Object? _error;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      final h = await Api.i.hoyDePueblo(widget.puebloId);
      if (mounted) {
        setState(() {
          _hoy = h;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hoy == null && _error != null) return ErrorReintentar(error: _error!, onReintentar: recargar);
    if (_hoy == null) return const Cargando();
    return HoyView(
      hoy: _hoy!.datos,
      deCache: _hoy!.deCache,
      guardadoEn: _hoy!.guardadoEn,
      onRefrescar: recargar,
      onEncargar: widget.onEncargar,
      titulo: widget.titulo,
    );
  }
}
