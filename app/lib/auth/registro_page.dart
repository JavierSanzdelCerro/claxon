import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../widgets/selector_pueblo.dart';

/// Registro de vecinos y familiares. Vendedores y ayuntamientos los da de alta el administrador.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  Rol _rol = Rol.VECINO;
  Pueblo? _pueblo;
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _telefono = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;

  Future<void> _crear() async {
    if (_nombre.text.trim().isEmpty || _usuario.text.trim().length < 3 || _clave.text.length < 6) {
      mostrarMensaje(
        context,
        'Rellena tu nombre, un usuario (3 letras o más) y una contraseña de 6 o más',
        error: true,
      );
      return;
    }
    if (_rol == Rol.VECINO && _pueblo == null) {
      mostrarMensaje(context, 'Elige tu pueblo', error: true);
      return;
    }
    setState(() => _cargando = true);
    try {
      final u = await Api.i.registrar({
        'username': _usuario.text.trim(),
        'password': _clave.text,
        'nombre': _nombre.text.trim(),
        'telefono': _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        'rol': _rol.name,
        'puebloId': _pueblo?.id,
      });
      if (mounted) Navigator.pop(context, u);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('¿Quién eres?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<Rol>(
                segments: const [
                  ButtonSegment(value: Rol.VECINO, label: Text('Vivo en el pueblo'), icon: Icon(Icons.home)),
                  ButtonSegment(value: Rol.FAMILIAR, label: Text('Soy familiar'), icon: Icon(Icons.family_restroom)),
                ],
                selected: {_rol},
                onSelectionChanged: (s) => setState(() => _rol = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Tu nombre'),
              ),
              const SizedBox(height: 12),
              if (_rol == Rol.VECINO) ...[
                SelectorPueblo(pueblo: _pueblo, etiqueta: 'Tu pueblo', onElegido: (p) => setState(() => _pueblo = p)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usuario,
                decoration: const InputDecoration(labelText: 'Usuario para entrar'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clave,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña (6 o más)'),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _cargando ? null : _crear, child: const Text('Crear cuenta')),
              if (_rol == Rol.FAMILIAR)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Después podrás vincularte con tu familiar usando el código de 6 cifras que aparece en su perfil.',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
