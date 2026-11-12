import 'package:material_ui/material_ui.dart';

import '../core/fechas.dart';
import '../core/modelos.dart';
import '../core/tema.dart';
import 'comunes.dart';

/// La pantalla «Hoy en mi pueblo» (RF3): qué vendedores pasan, a qué hora y si hay médico.
class HoyView extends StatelessWidget {
  final Hoy hoy;
  final bool deCache;
  final DateTime guardadoEn;
  final VoidCallback? onEncargar;
  final Future<void> Function() onRefrescar;
  final String? titulo;

  const HoyView({
    super.key,
    required this.hoy,
    required this.deCache,
    required this.guardadoEn,
    required this.onRefrescar,
    this.onEncargar,
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        if (deCache) SinConexion(guardadoEn: guardadoEn),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefrescar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(titulo ?? 'Hoy en ${hoy.pueblo.nombre}', style: t.titleLarge),
                  ),
                ),
                Text(
                  '${_mayuscula(fechaLarga(hoy.fecha))} · actualizado a las ${horaMinutos(hoy.actualizado)}',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final c in hoy.cambios) _TarjetaCambio(aviso: c),
                if (hoy.pasos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Hoy no pasa ningún vendedor por el pueblo.', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                for (final p in hoy.pasos) TarjetaPaso(paso: p),
                _TarjetaMedico(medico: hoy.medico, semana: hoy.consultasSemana),
                if (onEncargar != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onEncargar,
                    icon: const Icon(Icons.add_shopping_cart, size: 28),
                    label: const Text('Hacer un encargo'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _mayuscula(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class TarjetaPaso extends StatelessWidget {
  final Paso paso;
  const TarjetaPaso({super.key, required this.paso});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = Tema.colorTipo(paso.tipo);
    final (String estado, Color colorEstado) = switch (paso.estado) {
      'LLEGADO' => ('Ya ha pasado', Tema.gris),
      'EN_CAMINO' => (
        paso.minutosFaltan != null ? 'En camino · llega en ${paso.minutosFaltan} min' : 'En camino',
        Tema.verde,
      ),
      'SIN_SERVICIO_HOY' => ('Ruta terminada', Tema.gris),
      _ =>
        paso.minutosFaltan == null
            ? ('Aún no ha salido', const Color(0xFF6B5300))
            : ('Previsto', const Color(0xFF6B5300)),
    };
    final horaTxt = hora(paso.hora);
    final texto =
        '${paso.tipoEtiqueta}. ${paso.vendedor}. ${paso.lugar}, hacia las $horaTxt. $estado.'
        '${paso.retrasoMin > 5 ? ' Va con ${paso.retrasoMin} minutos de retraso.' : ''}';
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Tema.icono(paso.tipo), color: color, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paso.tipoEtiqueta, style: t.titleMedium),
                    Text('${paso.vendedor} · ${paso.lugar}', style: t.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      estado,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorEstado),
                    ),
                    if (paso.retrasoMin > 5 && paso.estado == 'EN_CAMINO')
                      Text(
                        'Va con ${paso.retrasoMin} min de retraso',
                        style: const TextStyle(fontSize: 16, color: Tema.rojo, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              Text(
                horaTxt,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: paso.estado == 'LLEGADO' ? Tema.gris : Tema.tinta,
                  decoration: paso.estado == 'LLEGADO' ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaMedico extends StatelessWidget {
  final Medico medico;
  final List<Aviso> semana;
  const _TarjetaMedico({required this.medico, required this.semana});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sin = medico.estado == 'SIN_CONSULTA';
    final con = medico.estado == 'CONSULTA';
    final titulo = con
        ? 'Consulta médica de ${hora(medico.horaInicio)} a ${hora(medico.horaFin)}'
        : 'Hoy no hay consulta médica';
    return Card(
      color: sin ? const Color(0xFFFDECEA) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: sin ? Tema.rojo : Tema.colorTipo('MEDICO'), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo, style: t.titleMedium?.copyWith(color: sin ? Tema.rojo : null)),
                ),
              ],
            ),
            if (sin && medico.texto != null) ...[const SizedBox(height: 6), Text(medico.texto!, style: t.bodyLarge)],
            if (semana.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Esta semana', style: t.titleSmall),
              for (final a in semana)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    a.tipo == 'CONSULTA'
                        ? '• ${_mayuscula(diaSemana(a.fecha))} ${a.fecha.day}: de ${hora(a.horaInicio)} a ${hora(a.horaFin)}'
                        : '• ${_mayuscula(diaSemana(a.fecha))} ${a.fecha.day}: sin consulta',
                    style: t.bodyMedium?.copyWith(color: a.tipo == 'SIN_CONSULTA' ? Tema.rojo : null),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaCambio extends StatelessWidget {
  final Aviso aviso;
  const _TarjetaCambio({required this.aviso});
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1C2),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign, size: 32, color: Tema.tinta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aviso del ayuntamiento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(aviso.resumen, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
