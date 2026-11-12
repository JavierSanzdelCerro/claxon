package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.*;
import es.claxon.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

/** Todo lo que hace el vendedor: su ruta (RF10), iniciarla (RF7), «He llegado» (RF8) y encargos (RF9). */
@Service
public class VendedorService {

    private final VendedorRepository vendedores;
    private final RutaRepository rutas;
    private final JornadaRepository jornadas;
    private final PuebloRepository pueblos;
    private final EncargoRepository encargos;
    private final EtaService eta;
    private final NotificacionService notificaciones;
    private final RelojClaxon reloj;

    public VendedorService(VendedorRepository vendedores, RutaRepository rutas, JornadaRepository jornadas,
                           PuebloRepository pueblos, EncargoRepository encargos, EtaService eta,
                           NotificacionService notificaciones, RelojClaxon reloj) {
        this.vendedores = vendedores;
        this.rutas = rutas;
        this.jornadas = jornadas;
        this.pueblos = pueblos;
        this.encargos = encargos;
        this.eta = eta;
        this.notificaciones = notificaciones;
        this.reloj = reloj;
    }

    // ---------------- Rutas ----------------

    @Transactional(readOnly = true)
    public List<RutaDto> misRutas(Usuario u) {
        return rutas.findByVendedorOrderByNombreAsc(vendedor(u)).stream().map(RutaDto::de).toList();
    }

    @Transactional
    public RutaDto crearRuta(Usuario u, RutaRequest req) {
        Ruta r = new Ruta();
        r.setVendedor(vendedor(u));
        aplicar(r, req);
        return RutaDto.de(rutas.save(r));
    }

    @Transactional
    public RutaDto editarRuta(Usuario u, Long id, RutaRequest req) {
        Ruta r = rutaPropia(u, id);
        aplicar(r, req);
        return RutaDto.de(rutas.save(r));
    }

    @Transactional
    public void borrarRuta(Usuario u, Long id) {
        Ruta r = rutaPropia(u, id);
        boolean conHistorico = jornadas.existsByRuta(r)
                || r.getParadas().stream().anyMatch(p -> encargos.existsByParadaId(p.getId()));
        if (conHistorico) {
            // No se borra para no perder el histórico de jornadas y encargos: se desactiva.
            r.setActiva(false);
        } else {
            rutas.delete(r);
        }
    }

    private void aplicar(Ruta r, RutaRequest req) {
        r.setNombre(req.nombre().trim());
        r.setDiasSemana(req.diasSemana());
        r.setHoraSalidaHabitual(req.horaSalidaHabitual());
        if (req.activa() != null) r.setActiva(req.activa());

        Map<Long, Parada> existentes = new HashMap<>();
        r.getParadas().forEach(p -> existentes.put(p.getId(), p));
        List<Parada> nuevas = new ArrayList<>();
        int orden = 1;
        int minAnterior = -1;
        for (ParadaRequest pr : req.paradas()) {
            if (pr.minDesdeSalida() < minAnterior) {
                throw ApiException.invalido("Los minutos de cada parada deben ser iguales o mayores que los de la anterior");
            }
            minAnterior = pr.minDesdeSalida();
            Parada p = pr.id() != null ? existentes.remove(pr.id()) : null;
            if (p == null) {
                p = new Parada();
                p.setRuta(r);
            }
            p.setPueblo(pueblos.findById(pr.puebloId()).orElseThrow(() -> ApiException.noEncontrado("Pueblo")));
            p.setLugar(pr.lugar().trim());
            p.setMinDesdeSalida(pr.minDesdeSalida());
            p.setOrden(orden++);
            nuevas.add(p);
        }
        for (Parada quitada : existentes.values()) {
            if (encargos.existsByParadaId(quitada.getId())) {
                throw ApiException.invalido("No se puede quitar la parada de " + quitada.getPueblo().getNombre()
                        + " porque tiene encargos. Desactiva la ruta o crea otra.");
            }
        }
        r.getParadas().clear();
        r.getParadas().addAll(nuevas);
    }

    // ---------------- Día de trabajo ----------------

    @Transactional(readOnly = true)
    public List<RutaHoyDto> hoy(Usuario u) {
        LocalDate hoy = reloj.hoy();
        List<RutaHoyDto> res = new ArrayList<>();
        for (Ruta r : rutas.findByVendedorOrderByNombreAsc(vendedor(u))) {
            if (!r.isActiva()) continue;
            res.add(rutaHoy(r, jornadas.findByRutaAndFecha(r, hoy).orElse(null), hoy));
        }
        // Primero las que tocan hoy o ya están en marcha.
        res.sort(Comparator.comparing((RutaHoyDto d) -> !(d.tocaHoy() || !"PREVISTA".equals(d.estadoJornada()))));
        return res;
    }

    @Transactional
    public RutaHoyDto iniciar(Usuario u, Long rutaId) {
        Ruta r = rutaPropia(u, rutaId);
        LocalDate hoy = reloj.hoy();
        Jornada j = jornadas.findByRutaAndFecha(r, hoy).orElseGet(() -> {
            Jornada nueva = new Jornada();
            nueva.setRuta(r);
            nueva.setFecha(hoy);
            return nueva;
        });
        if (j.getEstado() == EstadoJornada.TERMINADA) throw ApiException.invalido("La ruta de hoy ya está terminada");
        if (j.getEstado() == EstadoJornada.PREVISTA) {
            j.setHoraInicio(reloj.ahora().toLocalTime().truncatedTo(ChronoUnit.MINUTES));
            j.setEstado(EstadoJornada.EN_RUTA);
            j.setParadaActual(0);
            j.setRetrasoMin(0);
            jornadas.save(j);
        }
        notificaciones.revisarLlegadas();
        return rutaHoy(r, j, hoy);
    }

    /** «He llegado»: marca la parada (la siguiente si no se indica) y recalcula las demás. */
    @Transactional
    public RutaHoyDto heLlegado(Usuario u, Long rutaId, Long paradaId) {
        Ruta r = rutaPropia(u, rutaId);
        LocalDate hoy = reloj.hoy();
        Jornada j = jornadas.findByRutaAndFecha(r, hoy)
                .filter(x -> x.getEstado() == EstadoJornada.EN_RUTA)
                .orElseThrow(() -> ApiException.invalido("Primero pulsa «Iniciar ruta»"));
        Parada p;
        if (paradaId != null) {
            p = r.getParadas().stream().filter(x -> x.getId().equals(paradaId)).findFirst()
                    .orElseThrow(() -> ApiException.noEncontrado("Parada"));
            if (p.getOrden() <= j.getParadaActual()) throw ApiException.invalido("Ya habías llegado a esa parada");
        } else {
            p = r.getParadas().stream().filter(x -> x.getOrden() > j.getParadaActual()).findFirst()
                    .orElseThrow(() -> ApiException.invalido("No quedan paradas"));
        }
        LocalDateTime ahora = reloj.ahora();
        j.setRetrasoMin(eta.retrasoAlLlegar(j, p, ahora));
        j.setParadaActual(p.getOrden());
        if (p.getOrden() >= r.getParadas().size()) j.setEstado(EstadoJornada.TERMINADA);
        jornadas.save(j);
        notificaciones.revisarLlegadas();
        return rutaHoy(r, j, hoy);
    }

    @Transactional
    public RutaHoyDto terminar(Usuario u, Long rutaId) {
        Ruta r = rutaPropia(u, rutaId);
        LocalDate hoy = reloj.hoy();
        Jornada j = jornadas.findByRutaAndFecha(r, hoy).orElseThrow(() -> ApiException.invalido("Hoy no has iniciado esta ruta"));
        j.setEstado(EstadoJornada.TERMINADA);
        return rutaHoy(r, j, hoy);
    }

    private RutaHoyDto rutaHoy(Ruta r, Jornada j, LocalDate fecha) {
        Map<Long, int[]> cuenta = new HashMap<>();
        for (Encargo e : encargos.findDeRutaYFecha(r, fecha)) {
            int[] c = cuenta.computeIfAbsent(e.getParada().getId(), k -> new int[2]);
            c[1]++;
            if (e.getEstado() == EstadoEncargo.PENDIENTE) c[0]++;
        }
        boolean iniciada = j != null && j.getEstado() != EstadoJornada.PREVISTA;
        List<ParadaHoyDto> ps = new ArrayList<>();
        for (Parada p : r.getParadas()) {
            LocalDateTime hora = iniciada ? eta.estimada(j, p) : eta.prevista(r, p, fecha);
            int[] c = cuenta.getOrDefault(p.getId(), new int[2]);
            ps.add(new ParadaHoyDto(p.getId(), p.getOrden(), p.getPueblo().getNombre(), p.getLugar(),
                    hora == null ? null : hora.toLocalTime(), eta.estado(j, p).name(), c[0], c[1]));
        }
        return new RutaHoyDto(r.getId(), r.getNombre(), r.seHaceEl(fecha.getDayOfWeek()),
                j == null ? "PREVISTA" : j.getEstado().name(), iniciada ? j.getHoraInicio() : null,
                r.getHoraSalidaHabitual(), iniciada ? j.getRetrasoMin() : 0, ps);
    }

    // ---------------- Encargos ----------------

    @Transactional(readOnly = true)
    public List<EncargosParadaDto> encargosPorParada(Usuario u, Long rutaId, LocalDate fecha) {
        Ruta r = rutaPropia(u, rutaId);
        LocalDate dia = fecha == null ? reloj.hoy() : fecha;
        Jornada j = jornadas.findByRutaAndFecha(r, dia).orElse(null);
        boolean iniciada = j != null && j.getEstado() != EstadoJornada.PREVISTA;
        Map<Long, List<EncargoDto>> porParada = new HashMap<>();
        for (Encargo e : encargos.findDeRutaYFecha(r, dia)) {
            porParada.computeIfAbsent(e.getParada().getId(), k -> new ArrayList<>()).add(EncargoDto.de(e));
        }
        List<EncargosParadaDto> res = new ArrayList<>();
        for (Parada p : r.getParadas()) {
            LocalDateTime hora = iniciada ? eta.estimada(j, p) : eta.prevista(r, p, dia);
            res.add(new EncargosParadaDto(p.getId(), p.getOrden(), p.getPueblo().getNombre(), p.getLugar(),
                    hora == null ? null : hora.toLocalTime(), porParada.getOrDefault(p.getId(), List.of())));
        }
        return res;
    }

    @Transactional
    public EncargoDto entregar(Usuario u, Long encargoId, boolean entregado) {
        Encargo e = encargos.findById(encargoId).orElseThrow(() -> ApiException.noEncontrado("Encargo"));
        if (!e.getParada().getRuta().getVendedor().getId().equals(vendedor(u).getId())) throw ApiException.prohibido();
        if (e.getEstado() == EstadoEncargo.CANCELADO) throw ApiException.invalido("El vecino canceló este encargo");
        e.setEstado(entregado ? EstadoEncargo.ENTREGADO : EstadoEncargo.PENDIENTE);
        return EncargoDto.de(e);
    }

    /** HU10: encargos por semana de las últimas 8 semanas. */
    @Transactional(readOnly = true)
    public List<SemanaDto> estadisticas(Usuario u) {
        Vendedor v = vendedor(u);
        LocalDate lunes = reloj.hoy().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate desde = lunes.minusWeeks(7);
        List<Encargo> lista = encargos.findDeVendedorEntre(v, desde, lunes.plusDays(6));
        List<SemanaDto> res = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            LocalDate ini = desde.plusWeeks(i);
            LocalDate fin = ini.plusDays(6);
            List<Encargo> semana = lista.stream().filter(e -> !e.getFecha().isBefore(ini) && !e.getFecha().isAfter(fin)).toList();
            res.add(new SemanaDto(ini,
                    semana.stream().filter(e -> e.getEstado() != EstadoEncargo.CANCELADO).count(),
                    semana.stream().filter(e -> e.getEstado() == EstadoEncargo.ENTREGADO).count(),
                    semana.stream().filter(e -> e.getEstado() == EstadoEncargo.CANCELADO).count()));
        }
        return res;
    }

    // ---------------- Utilidades ----------------

    private Vendedor vendedor(Usuario u) {
        return vendedores.findByUsuario(u).orElseThrow(() -> ApiException.invalido("Esta cuenta no tiene ficha de vendedor"));
    }

    private Ruta rutaPropia(Usuario u, Long id) {
        Ruta r = rutas.findById(id).orElseThrow(() -> ApiException.noEncontrado("Ruta"));
        if (!r.getVendedor().getId().equals(vendedor(u).getId())) throw ApiException.prohibido();
        return r;
    }
}
