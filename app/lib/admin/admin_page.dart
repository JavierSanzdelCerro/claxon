import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_pueblo.dart';

/// Alta de vendedores y ayuntamientos (no pueden registrarse solos).
class AdminPage extends StatefulWidget {
  final VoidCallback onSalir;
  const AdminPage({super.key, required this.onSalir});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Usuario>? _usuarios;
  Rol _rol = Rol.VENDEDOR;
  String _tipo = 'PAN';
  Pueblo? _pueblo;
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _comercial = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await Api.i.get('/api/admin/usuarios') as List;
      if (mounted) setState(() => _usuarios = r.map((e) => Usuario.fromJson(e)).toList());
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _crear() async {
    try {
      await Api.i.post('/api/admin/usuarios', {
        'username': _usuario.text.trim(),
        'password': _clave.text,
        'nombre': _nombre.text.trim(),
        'rol': _rol.name,
        'puebloId': _pueblo?.id,
        if (_rol == Rol.VENDEDOR) 'nombreComercial': _comercial.text.trim(),
        if (_rol == Rol.VENDEDOR) 'tipo': _tipo,
      });
      for (final c in [_nombre, _usuario, _clave, _comercial]) {
        c.clear();
      }
      if (mounted) mostrarMensaje(context, 'Usuario creado');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administración'),
      actions: [IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onSalir, icon: const Icon(Icons.logout))],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Titulo('Dar de alta'),
            SegmentedButton<Rol>(
              segments: const [
                ButtonSegment(value: Rol.VENDEDOR, label: Text('Vendedor')),
                ButtonSegment(value: Rol.AYUNTAMIENTO, label: Text('Ayuntamiento')),
              ],
              selected: {_rol},
              onSelectionChanged: (s) => setState(() => _rol = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre de la persona o entidad'),
            ),
            const SizedBox(height: 8),
            if (_rol == Rol.VENDEDOR) ...[
              TextField(
                controller: _comercial,
                decoration: const InputDecoration(labelText: 'Nombre comercial'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Qué vende'),
                items: const [
                  DropdownMenuItem(value: 'PAN', child: Text('Pan')),
                  DropdownMenuItem(value: 'PESCADO', child: Text('Pescado')),
                  DropdownMenuItem(value: 'FRUTA', child: Text('Fruta')),
                  DropdownMenuItem(value: 'CARNE', child: Text('Carne')),
                  DropdownMenuItem(value: 'VARIOS', child: Text('Varios')),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
            ] else
              SelectorPueblo(pueblo: _pueblo, onElegido: (p) => setState(() => _pueblo = p)),
            const SizedBox(height: 8),
            TextField(
              controller: _usuario,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clave,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña inicial'),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _crear, child: const Text('Crear')),
            Titulo('Usuarios'),
            if (_usuarios == null) const Cargando(),
            for (final u in _usuarios ?? <Usuario>[])
              ListTile(
                title: Text('${u.nombre} (${u.username})'),
                subtitle: Text(
                  [
                    u.rol.name,
                    if (u.pueblo != null) u.pueblo!.nombre,
                    if (u.nombreComercial != null) u.nombreComercial!,
                  ].join(' · '),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
