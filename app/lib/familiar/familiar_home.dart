import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';
import '../widgets/vigia_avisos.dart';
import 'vecino_detalle_page.dart';

/// Modo familiar (HU6): ver y gestionar a distancia los avisos y encargos de un familiar mayor.
class FamiliarHome extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onSalir;
  const FamiliarHome({super.key, required this.usuario, required this.onSalir});
  @override
  State<FamiliarHome> createState() => _FamiliarHomeState();
}

class _FamiliarHomeState extends State<FamiliarHome> {
  List<VecinoVinculado>? _vecinos;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.i.get('/api/familia/vecinos') as List;
      if (mounted) {
        setState(() {
          _vecinos = r.map((e) => VecinoVinculado.fromJson(e)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _vincular() async {
    final codigo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Vincular con un familiar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escribe el código de 6 cifras que aparece en el perfil de su app.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codigo,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 28, letterSpacing: 6),
              decoration: const InputDecoration(labelText: 'Código'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Vincular')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await Api.i.post('/api/familia/vincular', {'codigo': codigo.text.trim()});
      if (mounted) mostrarMensaje(context, 'Ya estás vinculado con ${r['nombre']}');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return VigiaAvisos(
      onNuevos: _cargar,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi familia'),
          actions: [
            BotonRelojDemo(onCambio: _cargar),
            IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onSalir, icon: const Icon(Icons.logout)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _vincular,
          icon: const Icon(Icons.link),
          label: const Text('Vincular familiar', style: TextStyle(fontSize: 18)),
        ),
        body: _vecinos == null
            ? (_error != null ? ErrorReintentar(error: _error!, onReintentar: _cargar) : const Cargando())
            : RefreshIndicator(
                onRefresh: _cargar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    Text('Hola, ${widget.usuario.nombre.split(' ').first}', style: t.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Recibes los mismos avisos que tu familia y puedes hacer encargos por ellos.',
                      style: t.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_vecinos!.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aún no tienes a nadie vinculado. Pulsa «Vincular familiar» e introduce su código.',
                            style: TextStyle(fontSize: 19),
                          ),
                        ),
                      ),
                    for (final v in _vecinos!)
                      Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VecinoDetallePage(vecino: v)),
                            );
                            _cargar();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Tema.ambar,
                                  child: Text(v.nombre[0], style: const TextStyle(fontSize: 26, color: Tema.tinta)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v.nombre, style: t.titleMedium),
                                      Text(v.pueblo?.nombre ?? 'Sin pueblo', style: t.bodyMedium),
                                      if (v.ultimoAviso != null) ...[
                                        const SizedBox(height: 6),
                                        Text('Último aviso: ${v.ultimoAviso!.titulo}', style: t.bodySmall),
                                        v.ultimoAviso!.vistaEn != null
                                            ? Text(
                                                'Lo vio a las ${horaMinutos(v.ultimoAviso!.vistaEn!)}',
                                                style: const TextStyle(
                                                  color: Tema.verde,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              )
                                            : const Text(
                                                'Aún no lo ha visto',
                                                style: TextStyle(
                                                  color: Tema.rojo,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
