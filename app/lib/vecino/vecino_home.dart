import 'package:material_ui/material_ui.dart';

import '../core/modelos.dart';
import '../widgets/comunes.dart';
import '../widgets/vigia_avisos.dart';
import 'avisos_tab.dart';
import 'encargo_page.dart';
import 'encargos_tab.dart';
import 'hoy_tab.dart';
import 'perfil_tab.dart';

/// App del vecino: cuatro pestañas como máximo (RNF2).
class VecinoHome extends StatefulWidget {
  final Usuario usuario;
  final ValueChanged<Usuario> onCambioUsuario;
  final VoidCallback onSalir;
  const VecinoHome({super.key, required this.usuario, required this.onCambioUsuario, required this.onSalir});
  @override
  State<VecinoHome> createState() => _VecinoHomeState();
}

class _VecinoHomeState extends State<VecinoHome> {
  int _tab = 0;
  final _hoy = GlobalKey<HoyTabState>();
  final _encargos = GlobalKey<EncargosTabState>();
  final _avisos = GlobalKey<AvisosTabState>();

  Future<void> _nuevoEncargo() async {
    final pueblo = widget.usuario.pueblo;
    if (pueblo == null) {
      setState(() => _tab = 3);
      return;
    }
    final hecho = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EncargoPage(puebloId: pueblo.id)),
    );
    if (hecho == true) {
      _encargos.currentState?.recargar();
      setState(() => _tab = 1);
    }
  }

  void _refrescarTodo() {
    _hoy.currentState?.recargar();
    _encargos.currentState?.recargar();
    _avisos.currentState?.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final pueblo = u.pueblo;
    final paginas = [
      pueblo == null
          ? const Center(child: Text('Elige tu pueblo en «Perfil»', style: TextStyle(fontSize: 22)))
          : HoyTab(key: _hoy, puebloId: pueblo.id, onEncargar: _nuevoEncargo),
      EncargosTab(key: _encargos, onNuevo: _nuevoEncargo),
      AvisosTab(key: _avisos),
      PerfilTab(usuario: u, onCambio: widget.onCambioUsuario, onSalir: widget.onSalir),
    ];
    return VigiaAvisos(
      onNuevos: _refrescarTodo,
      child: Scaffold(
        appBar: AppBar(
          title: Text(['Hoy', 'Mis encargos', 'Avisos', 'Perfil'][_tab]),
          actions: [BotonRelojDemo(onCambio: _refrescarTodo)],
        ),
        body: IndexedStack(index: _tab, children: paginas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            setState(() => _tab = i);
            if (i == 0) _hoy.currentState?.recargar();
            if (i == 1) _encargos.currentState?.recargar();
            if (i == 2) _avisos.currentState?.recargar();
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today), label: 'Hoy'),
            NavigationDestination(icon: Icon(Icons.shopping_basket), label: 'Encargos'),
            NavigationDestination(icon: Icon(Icons.notifications), label: 'Avisos'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
