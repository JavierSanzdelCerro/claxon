import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/modelos.dart';

/// Campo para elegir uno de los 236 pueblos de Teruel buscando por nombre.
class SelectorPueblo extends StatelessWidget {
  final Pueblo? pueblo;
  final String etiqueta;
  final ValueChanged<Pueblo> onElegido;
  const SelectorPueblo({super.key, this.pueblo, required this.onElegido, this.etiqueta = 'Pueblo'});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final p = await showDialog<Pueblo>(context: context, builder: (_) => const _BuscarPueblo());
      if (p != null) onElegido(p);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: const Icon(Icons.search),
      ),
      child: Text(pueblo?.nombre ?? 'Toca para elegir', style: const TextStyle(fontSize: 20)),
    ),
  );
}

class _BuscarPueblo extends StatefulWidget {
  const _BuscarPueblo();
  @override
  State<_BuscarPueblo> createState() => _BuscarPuebloState();
}

class _BuscarPuebloState extends State<_BuscarPueblo> {
  List<Pueblo> _lista = [];
  Timer? _espera;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  void _buscar(String q) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 250), () async {
      try {
        final r = await Api.i.buscarPueblos(q);
        if (mounted) {
          setState(() {
            _lista = r;
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _error = '$e');
      }
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: _buscar,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Escribe el nombre del pueblo',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
          Expanded(
            child: ListView.builder(
              itemCount: _lista.length,
              itemBuilder: (_, i) {
                final p = _lista[i];
                return ListTile(
                  minTileHeight: 56,
                  title: Text(p.nombre, style: const TextStyle(fontSize: 20)),
                  subtitle: Text(p.comarca ?? ''),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
