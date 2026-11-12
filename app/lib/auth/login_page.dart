import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import '../widgets/comunes.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  final void Function(Usuario) onEntrar;
  const LoginPage({super.key, required this.onEntrar});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  bool _demo = false;

  @override
  void initState() {
    super.initState();
    Api.i.relojDemo().then((h) => mounted ? setState(() => _demo = h != null) : null);
  }

  Future<void> _entrar() async {
    if (_usuario.text.trim().isEmpty || _clave.text.isEmpty) {
      mostrarMensaje(context, 'Escribe tu usuario y tu contraseña', error: true);
      return;
    }
    setState(() => _cargando = true);
    try {
      final u = await Api.i.login(_usuario.text.trim(), _clave.text);
      widget.onEntrar(u);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _rellenar(String u) {
    _usuario.text = u;
    _clave.text = 'claxon123';
    _entrar();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 8),
                    Text(
                      'Te avisamos 15 minutos antes de que llegue el panadero, el pescadero o el médico.',
                      textAlign: TextAlign.center,
                      style: t.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _usuario,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 20),
                      decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _clave,
                      obscureText: !_verClave,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _entrar(),
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _verClave ? 'Ocultar contraseña' : 'Ver contraseña',
                          icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _verClave = !_verClave),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final u = await Navigator.push<Usuario>(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistroPage()),
                        );
                        if (u != null) widget.onEntrar(u);
                      },
                      child: const Text('Crear una cuenta nueva'),
                    ),
                    if (_demo) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      Text(
                        'Cuentas de demostración (contraseña claxon123)',
                        style: t.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (u, txt) in [
                            ('carmen', 'Carmen · vecina'),
                            ('lucia', 'Lucía · familiar'),
                            ('pan.martin', 'Panadero'),
                            ('pescados.lola', 'Pescadera'),
                            ('ayto.fuenferrada', 'Ayuntamiento'),
                            ('admin', 'Admin'),
                          ])
                            ActionChip(label: Text(txt), onPressed: () => _rellenar(u)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/tablon'),
                        icon: const Icon(Icons.tv),
                        label: const Text('Ver el tablón del bar'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(color: Tema.ambar, borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.campaign, size: 60, color: Tema.tinta),
      ),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: const Text(
          'CLAXON',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4, color: Tema.verde),
        ),
      ),
    ],
  );
}
