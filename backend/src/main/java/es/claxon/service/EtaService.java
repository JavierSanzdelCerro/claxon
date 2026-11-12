package es.claxon.service;

import es.claxon.model.EstadoJornada;
import es.claxon.model.Jornada;
import es.claxon.model.Parada;
import es.claxon.model.Ruta;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Cálculo de la hora estimada de llegada (RF11).
 *
 * <pre>
 *   hora estimada = hora de salida + minutos hasta la parada + retraso medido
 * </pre>
 *
 * El retraso se mide cada vez que el vendedor pulsa «He llegado»: es la diferencia
 * entre la hora real y la que se había calculado para esa parada. Si el vendedor
 * se queda sin red, el retraso se mantiene y se sigue usando su horario.
 */
@Service
public class EtaService {

    /** Estado de una parada para mostrarlo en pantalla. */
    public enum EstadoParada { PREVISTA, EN_CAMINO, LLEGADO, SIN_SERVICIO_HOY }

    /** Hora estimada de una parada en una jornada en curso o ya iniciada. */
    public LocalDateTime estimada(Jornada jornada, Parada parada) {
        LocalTime salida = jornada.getHoraInicio() != null
                ? jornada.getHoraInicio()
                : jornada.getRuta().getHoraSalidaHabitual();
        if (salida == null) return null;
        LocalDateTime base = LocalDateTime.of(jornada.getFecha(), salida).plusMinutes(parada.getMinDesdeSalida());
        // El retraso solo afecta a las paradas a las que aún no ha llegado.
        if (jornada.getEstado() == EstadoJornada.EN_RUTA && parada.getOrden() > jornada.getParadaActual()) {
            base = base.plusMinutes(jornada.getRetrasoMin());
        }
        return base;
    }

    /** Hora prevista según el horario habitual, cuando aún no hay jornada iniciada. */
    public LocalDateTime prevista(Ruta ruta, Parada parada, LocalDate fecha) {
        if (ruta.getHoraSalidaHabitual() == null) return null;
        return LocalDateTime.of(fecha, ruta.getHoraSalidaHabitual()).plusMinutes(parada.getMinDesdeSalida());
    }

    /** Retraso (en minutos) que supone llegar a la parada a la hora indicada. */
    public int retrasoAlLlegar(Jornada jornada, Parada parada, LocalDateTime llegadaReal) {
        LocalDateTime sinRetraso = LocalDateTime.of(jornada.getFecha(), jornada.getHoraInicio())
                .plusMinutes(parada.getMinDesdeSalida());
        return (int) Duration.between(sinRetraso, llegadaReal).toMinutes();
    }

    public EstadoParada estado(Jornada jornada, Parada parada) {
        if (jornada == null || jornada.getEstado() == EstadoJornada.PREVISTA) return EstadoParada.PREVISTA;
        if (parada.getOrden() <= jornada.getParadaActual()) return EstadoParada.LLEGADO;
        if (jornada.getEstado() == EstadoJornada.TERMINADA) return EstadoParada.SIN_SERVICIO_HOY;
        return EstadoParada.EN_CAMINO;
    }
}
