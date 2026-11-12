package es.claxon.service;

import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.*;
import es.claxon.repository.AvisoRepository;
import es.claxon.repository.JornadaRepository;
import es.claxon.repository.RutaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Construye la vista «Hoy en mi pueblo» (RF3). La usan la app del vecino, la del familiar,
 * el panel del ayuntamiento y el tablón del bar, así que todos ven exactamente lo mismo.
 */
@Service
public class HoyService {

    private final RutaRepository rutas;
    private final JornadaRepository jornadas;
    private final AvisoRepository avisos;
    private final EtaService eta;
    private final RelojClaxon reloj;

    public HoyService(RutaRepository rutas, JornadaRepository jornadas, AvisoRepository avisos,
                      EtaService eta, RelojClaxon reloj) {
        this.rutas = rutas;
        this.jornadas = jornadas;
        this.avisos = avisos;
        this.eta = eta;
        this.reloj = reloj;
    }

    @Transactional(readOnly = true)
    public HoyDto de(Pueblo pueblo, LocalDate fecha) {
        LocalDateTime ahora = reloj.ahora();
        List<PasoDto> pasos = new ArrayList<>();

        for (Ruta ruta : rutas.findActivasQuePasanPor(pueblo)) {
            Optional<Jornada> jornada = jornadas.findByRutaAndFecha(ruta, fecha);
            // Pasa hoy si es uno de sus días o si el vendedor ha salido igualmente.
            if (!ruta.seHaceEl(fecha.getDayOfWeek()) && jornada.isEmpty()) continue;
            Vendedor v = ruta.getVendedor();
            for (Parada p : ruta.getParadas()) {
                if (!p.getPueblo().getId().equals(pueblo.getId())) continue;
                Jornada j = jornada.orElse(null);
                boolean iniciada = j != null && j.getEstado() != EstadoJornada.PREVISTA;
                LocalDateTime hora = iniciada ? eta.estimada(j, p) : eta.prevista(ruta, p, fecha);
                EtaService.EstadoParada estado = eta.estado(j, p);
                Long faltan = null;
                if (hora != null && estado != EtaService.EstadoParada.LLEGADO && hora.isAfter(ahora)) {
                    faltan = (Duration.between(ahora, hora).toSeconds() + 59) / 60;
                }
                pasos.add(new PasoDto(ruta.getId(), p.getId(), v.getNombreComercial(), v.getTipo(),
                        v.getTipo().getEtiqueta(), p.getLugar(), hora == null ? null : hora.toLocalTime(),
                        estado.name(), faltan, iniciada ? j.getRetrasoMin() : 0, iniciada));
            }
        }
        pasos.sort(Comparator.comparing(PasoDto::hora, Comparator.nullsLast(Comparator.naturalOrder())));

        List<Aviso> deHoy = avisos.findByPuebloAndFechaOrderByCreadoEnAsc(pueblo, fecha);
        MedicoDto medico = medico(deHoy);
        List<AvisoDto> cambios = deHoy.stream().filter(a -> a.getTipo() == TipoAviso.CAMBIO)
                .map(a -> AvisoService.dto(a, fecha)).toList();

        LocalDate lunes = fecha.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        List<AvisoDto> semana = avisos.findByPuebloAndFechaBetweenOrderByFechaAscHoraInicioAsc(pueblo, lunes, lunes.plusDays(6))
                .stream().filter(a -> a.getTipo() != TipoAviso.CAMBIO)
                .map(a -> AvisoService.dto(a, fecha)).toList();

        return new HoyDto(PuebloDto.de(pueblo), fecha, ahora, pasos, medico, cambios, semana);
    }

    /** Si hay un «sin consulta» para hoy, manda sobre cualquier consulta publicada antes. */
    private MedicoDto medico(List<Aviso> deHoy) {
        Optional<Aviso> sin = deHoy.stream().filter(a -> a.getTipo() == TipoAviso.SIN_CONSULTA)
                .max(Comparator.comparing(Aviso::getCreadoEn));
        if (sin.isPresent()) {
            return new MedicoDto("SIN_CONSULTA", sin.get().getTexto() == null ? "Hoy no hay consulta médica" : sin.get().getTexto(), null, null);
        }
        Optional<Aviso> con = deHoy.stream().filter(a -> a.getTipo() == TipoAviso.CONSULTA)
                .max(Comparator.comparing(Aviso::getCreadoEn));
        return con.map(a -> new MedicoDto("CONSULTA", a.getTexto(), a.getHoraInicio(), a.getHoraFin()))
                .orElse(new MedicoDto("NO_HAY", "Hoy no hay consulta médica en el pueblo", null, null));
    }
}
