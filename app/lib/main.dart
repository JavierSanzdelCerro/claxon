import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'admin/admin_page.dart';
import 'auth/login_page.dart';
import 'ayuntamiento/panel_page.dart';
import 'core/api.dart';
import 'core/modelos.dart';
import 'core/tema.dart';
import 'familiar/familiar_home.dart';
import 'tablon/tablon_page.dart';
import 'vecino/vecino_home.dart';
import 'vendedor/vendedor_home.dart';
import 'widgets/comunes.dart';

void main() {
  runApp(const ClaxonApp());
}

/// Un solo proyecto Flutter para todos: app del vecino, familiar y vendedor (Android),
/// y panel del ayuntamiento y tablón del bar (web).
class ClaxonApp extends StatelessWidget {
  const ClaxonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLAXON',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro(),
      locale: const Locale('es', 'ES'),
      initialRoute: '/',
      onGenerateRoute: (ajustes) {
        final ruta = ajustes.name ?? '/';
        // Tablón del bar sin iniciar sesión: /#/tablon/12
        if (ruta.startsWith('/tablon')) {
          final id = int.tryParse(ruta.split('/').length > 2 ? ruta.split('/')[2] : '');
          return MaterialPageRoute(
            settings: ajustes,
            builder: (_) => TablonPage(puebloId: id),
          );
        }
        return MaterialPageRoute(settings: ajustes, builder: (_) => const Inicio());
      },
    );
  }
}

/// Decide qué pantalla ve cada usuario según su rol (RF1).
class Inicio extends StatefulWidget {
  const Inicio({super.key});
  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  Usuario? _usuario;
  bool _cargando = true;
  Object? _error;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _arrancar();
    _sub = Api.i.sesionCerrada.stream.listen((_) => _salir());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _arrancar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final u = await Api.i.iniciar();
      if (mounted) setState(() => _usuario = u);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _salir() async {
    await Api.i.cerrarSesion();
    if (mounted) setState(() => _usuario = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Cargando());
    if (_error != null) {
      return Scaffold(
        body: ErrorReintentar(error: _error!, onReintentar: _arrancar),
      );
    }
    final u = _usuario;
    if (u == null) return LoginPage(onEntrar: (u) => setState(() => _usuario = u));

    final pantalla = switch (u.rol) {
      Rol.VECINO => VecinoHome(usuario: u, onCambioUsuario: (n) => setState(() => _usuario = n), onSalir: _salir),
      Rol.FAMILIAR => FamiliarHome(usuario: u, onSalir: _salir),
      Rol.VENDEDOR => VendedorHome(usuario: u, onSalir: _salir),
      Rol.AYUNTAMIENTO => PanelPage(usuario: u, onSalir: _salir),
      Rol.ADMIN => AdminPage(onSalir: _salir),
    };
    // «Letra más grande» multiplica el tamaño que ya tenga el móvil (RNF1).
    final escala = u.textoGrande && (u.rol == Rol.VECINO) ? 1.15 : 1.0;
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1) * escala)),
      child: pantalla,
    );
  }
}
