import 'package:material_ui/material_ui.dart';

import '../core/modelos.dart';
import '../widgets/comunes.dart';
import 'encargos_vendedor_tab.dart';
import 'mis_rutas_tab.dart';
import 'ruta_hoy_tab.dart';
import 'semana_tab.dart';

/// App del vendedor: botones enormes para usarla en la furgoneta.
class VendedorHome extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onSalir;
  const VendedorHome({super.key, required this.usuario, required this.onSalir});
  @override
  State<VendedorHome> createState() => _VendedorHomeState();
}

class _VendedorHomeState extends State<VendedorHome> {
  int _tab = 0;
  final _ruta = GlobalKey<RutaHoyTabState>();
  final _encargos = GlobalKey<EncargosVendedorTabState>();
  final _semana = GlobalKey<SemanaTabState>();

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return Scaffold(
      appBar: AppBar(
        title: Text(u.nombreComercial ?? u.nombre),
        actions: [
          BotonRelojDemo(onCambio: () => _ruta.currentState?.recargar()),
          IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onSalir, icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          RutaHoyTab(key: _ruta, onVerEncargos: () => setState(() => _tab = 1)),
          EncargosVendedorTab(key: _encargos),
          const MisRutasTab(),
          SemanaTab(key: _semana),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 0) _ruta.currentState?.recargar();
          if (i == 1) _encargos.currentState?.recargar();
          if (i == 3) _semana.currentState?.recargar();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Ruta'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Encargos'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Mis rutas'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Semanas'),
        ],
      ),
    );
  }
}
