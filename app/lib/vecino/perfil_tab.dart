import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_pueblo.dart';
import 'suscripciones_view.dart';

class PerfilTab extends StatelessWidget {
  final Usuario usuario;
  final ValueChanged<Usuario> onCambio;
  final VoidCallback onSalir;
  const PerfilTab({super.key, required this.usuario, required this.onCambio, required this.onSalir});

  Future<void> _guardar(BuildContext context, Map<String, dynamic> cambios) async {
    try {
      final r = await Api.i.put('/api/me', cambios);
      onCambio(Usuario.fromJson(r));
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = usuario;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(u.nombre, style: t.titleLarge),
        if (u.telefono != null) Text(u.telefono!, style: t.bodyMedium),
        const SizedBox(height: 12),
        SelectorPueblo(
          etiqueta: 'Mi pueblo',
          pueblo: u.pueblo,
          onElegido: (p) => _guardar(context, {'puebloId': p.id}),
        ),
        if (u.pueblo != null) ...[Titulo('Quiero aviso de'), SuscripcionesView(pueblo: u.pueblo!)],
        Titulo('Letra'),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.text_increase, size: 32),
            title: const Text('Letra más grande', style: TextStyle(fontSize: 20)),
            value: u.textoGrande,
            onChanged: (v) => _guardar(context, {'textoGrande': v}),
          ),
        ),
        if (u.codigoVinculo != null) ...[
          Titulo('Código para tu familia'),
          Card(
            color: Tema.ambar.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Semantics(
                    label: 'Código ${u.codigoVinculo!.split('').join(' ')}',
                    excludeSemantics: true,
                    child: Text(
                      u.codigoVinculo!,
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 8),
                    ),
                  ),
                  const Text(
                    'Dale este código a tu hijo o hija para que pueda ver tus avisos y hacer encargos por ti desde su móvil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: onSalir, icon: const Icon(Icons.logout), label: const Text('Cerrar sesión')),
      ],
    );
  }
}
