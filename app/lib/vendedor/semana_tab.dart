import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';

/// Encargos por semana (HU10), para planificar la compra.
class SemanaTab extends StatefulWidget {
  const SemanaTab({super.key});
  @override
  State<SemanaTab> createState() => SemanaTabState();
}

class SemanaTabState extends State<SemanaTab> {
  List<Semana>? _semanas;
  Object? _error;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  Future<void> recargar() async {
    try {
      final r = await Api.i.get('/api/vendedor/estadisticas') as List;
      if (mounted) {
        setState(() {
          _semanas = r.map((e) => Semana.fromJson(e)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_semanas == null) {
      return _error != null ? ErrorReintentar(error: _error!, onReintentar: recargar) : const Cargando();
    }
    final maximo = _semanas!.fold<int>(1, (m, s) => s.encargos > m ? s.encargos : m);
    final total = _semanas!.fold<int>(0, (m, s) => m + s.encargos);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Encargos de las últimas 8 semanas', style: Theme.of(context).textTheme.titleMedium),
        Text(
          '$total en total · media de ${(total / 8).toStringAsFixed(1)} por semana',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final s in _semanas!.reversed)
          Semantics(
            label: 'Semana del ${s.lunes.day} del ${s.lunes.month}: ${s.encargos} encargos, ${s.entregados} entregados',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text('${s.lunes.day}/${s.lunes.month}', style: const TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Stack(
                        children: [
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEAE2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            height: 34,
                            width: c.maxWidth * s.encargos / maximo,
                            decoration: BoxDecoration(color: Tema.verde, borderRadius: BorderRadius.circular(8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${s.encargos}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
