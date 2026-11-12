package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.*;
import es.claxon.repository.AvisoRepository;
import es.claxon.repository.SuscripcionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.List;
import java.util.Locale;

/** Avisos del ayuntamiento: días de consulta médica y cambios de última hora (RF12). */
@Service
public class AvisoService {

    private static final Locale ES = Locale.forLanguageTag("es-ES");
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("H:mm");

    private final AvisoRepository avisos;
    private final SuscripcionRepository suscripciones;
    private final NotificacionService notificaciones;
    private final HoyService hoy;
    private final RelojClaxon reloj;

    public AvisoService(AvisoRepository avisos, SuscripcionRepository suscripciones,
                        NotificacionService notificaciones, HoyService hoy, RelojClaxon reloj) {
        this.avisos = avisos;
        this.suscripciones = suscripciones;
        this.notificaciones = notificaciones;
        this.hoy = hoy;
        this.reloj = reloj;
    }

    @Transactional
    public PublicadoDto publicar(Usuario ayto, AvisoRequest req) {
        Pueblo pueblo = puebloDe(ayto);
        if (req.fecha().isBefore(reloj.hoy())) throw ApiException.invalido("La fecha ya ha pasado");
        if (req.tipo() == TipoAviso.CONSULTA && (req.horaInicio() == null || req.horaFin() == null)) {
            throw ApiException.invalido("Indica el horario de la consulta");
        }
        if (req.tipo() == TipoAviso.CONSULTA && !req.horaFin().isAfter(req.horaInicio())) {
            throw ApiException.invalido("La hora de fin debe ser posterior a la de inicio");
        }
        if (req.tipo() == TipoAviso.CAMBIO && (req.texto() == null || req.texto().isBlank())) {
            throw ApiException.invalido("Escribe el mensaje del aviso");
        }
        Aviso a = new Aviso();
        a.setPueblo(pueblo);
        a.setAutor(ayto);
        a.setTipo(req.tipo());
        a.setFecha(req.fecha());
        a.setHoraInicio(req.tipo() == TipoAviso.CONSULTA ? req.horaInicio() : null);
        a.setHoraFin(req.tipo() == TipoAviso.CONSULTA ? req.horaFin() : null);
        a.setTexto(req.texto() == null || req.texto().isBlank() ? null : req.texto().trim());
        a.setCreadoEn(reloj.ahora());
        avisos.save(a);
        int avisados = notificaciones.avisarPublicacion(a);
        return new PublicadoDto(dto(a, reloj.hoy()), avisados);
    }

    @Transactional
    public void borrar(Usuario ayto, Long id) {
        Aviso a = avisos.findById(id).orElseThrow(() -> ApiException.noEncontrado("Aviso"));
        if (!a.getPueblo().getId().equals(puebloDe(ayto).getId())) throw ApiException.prohibido();
        avisos.delete(a);
    }

    @Transactional(readOnly = true)
    public PanelDto panel(Usuario ayto) {
        Pueblo p = puebloDe(ayto);
        LocalDate hoyF = reloj.hoy();
        List<AvisoDto> proximos = avisos.findByPuebloAndFechaBetweenOrderByFechaAscHoraInicioAsc(p, hoyF, hoyF.plusDays(30))
                .stream().map(a -> dto(a, hoyF)).toList();
        return new PanelDto(PuebloDto.de(p), suscripciones.contarVecinosSuscritos(p), hoy.de(p, hoyF), proximos);
    }

    private Pueblo puebloDe(Usuario ayto) {
        if (ayto.getPueblo() == null) throw ApiException.invalido("Esta cuenta de ayuntamiento no tiene pueblo asignado");
        return ayto.getPueblo();
    }

    public static AvisoDto dto(Aviso a, LocalDate hoy) {
        return new AvisoDto(a.getId(), a.getTipo(), a.getFecha(), a.getHoraInicio(), a.getHoraFin(), a.getTexto(),
                describir(a, hoy), a.getCreadoEn());
    }

    /** Frase lista para leer: «Hoy no hay consulta. Centro de salud de Utrillas.» */
    public static String describir(Aviso a, LocalDate hoy) {
        String cuando = cuando(a.getFecha(), hoy);
        String extra = a.getTexto() == null ? "" : " " + a.getTexto();
        return switch (a.getTipo()) {
            case CONSULTA -> cuando + " hay consulta médica de " + a.getHoraInicio().format(HH_MM)
                    + " a " + a.getHoraFin().format(HH_MM) + "." + extra;
            case SIN_CONSULTA -> cuando + " no hay consulta médica." + extra;
            case CAMBIO -> a.getTexto() == null ? cuando : (a.getFecha().equals(hoy) ? a.getTexto() : cuando + ": " + a.getTexto());
        };
    }

    static String cuando(LocalDate fecha, LocalDate hoy) {
        if (fecha.equals(hoy)) return "Hoy";
        if (fecha.equals(hoy.plusDays(1))) return "Mañana";
        String dia = fecha.getDayOfWeek().getDisplayName(TextStyle.FULL, ES);
        return "El " + dia + " " + fecha.getDayOfMonth();
    }
}
