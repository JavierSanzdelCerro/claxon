package es.claxon.service;

import es.claxon.model.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.*;

/** Pruebas del cálculo de la hora de llegada con el ejemplo de la propuesta. */
class EtaServiceTest {

    private final EtaService eta = new EtaService();
    private Ruta ruta;
    private Parada martin, fuenferrada, segura, hoz;
    private Jornada jornada;
    private final LocalDate dia = LocalDate.of(2026, 11, 12);

    @BeforeEach
    void preparar() {
        ruta = new Ruta();
        ruta.setHoraSalidaHabitual(LocalTime.of(10, 0));
        martin = parada(1, 0);
        fuenferrada = parada(2, 40);
        segura = parada(3, 80);
        hoz = parada(4, 120);
        jornada = new Jornada();
        jornada.setRuta(ruta);
        jornada.setFecha(dia);
        jornada.setHoraInicio(LocalTime.of(10, 0));
        jornada.setEstado(EstadoJornada.EN_RUTA);
    }

    private Parada parada(int orden, int min) {
        Parada p = new Parada();
        p.setRuta(ruta);
        p.setOrden(orden);
        p.setMinDesdeSalida(min);
        ruta.getParadas().add(p);
        return p;
    }

    @Test
    void horaEstimadaEsSalidaMasMinutos() {
        assertEquals(LocalDateTime.of(dia, LocalTime.of(10, 40)), eta.estimada(jornada, fuenferrada));
        assertEquals(LocalDateTime.of(dia, LocalTime.of(11, 20)), eta.estimada(jornada, segura));
        assertEquals(LocalDateTime.of(dia, LocalTime.of(12, 0)), eta.estimada(jornada, hoz));
    }

    @Test
    void heLlegadoTardeRetrasaLasSiguientes() {
        // Llega a Fuenferrada a las 10:52 en vez de a las 10:40: 12 minutos de retraso.
        int retraso = eta.retrasoAlLlegar(jornada, fuenferrada, LocalDateTime.of(dia, LocalTime.of(10, 52)));
        assertEquals(12, retraso);
        jornada.setRetrasoMin(retraso);
        jornada.setParadaActual(2);
        assertEquals(LocalTime.of(11, 32), eta.estimada(jornada, segura).toLocalTime());
        assertEquals(LocalTime.of(12, 12), eta.estimada(jornada, hoz).toLocalTime());
        // A las que ya pasó no se les suma el retraso.
        assertEquals(LocalTime.of(10, 0), eta.estimada(jornada, martin).toLocalTime());
    }

    @Test
    void ir_adelantadoAdelantaLasSiguientes() {
        int retraso = eta.retrasoAlLlegar(jornada, fuenferrada, LocalDateTime.of(dia, LocalTime.of(10, 33)));
        assertEquals(-7, retraso);
        jornada.setRetrasoMin(retraso);
        jornada.setParadaActual(2);
        assertEquals(LocalTime.of(11, 13), eta.estimada(jornada, segura).toLocalTime());
    }

    @Test
    void sinJornadaSeUsaElHorarioHabitual() {
        assertEquals(LocalTime.of(11, 20), eta.prevista(ruta, segura, dia).toLocalTime());
        assertEquals(EtaService.EstadoParada.PREVISTA, eta.estado(null, segura));
    }

    @Test
    void estadosDeLasParadas() {
        jornada.setParadaActual(2);
        assertEquals(EtaService.EstadoParada.LLEGADO, eta.estado(jornada, fuenferrada));
        assertEquals(EtaService.EstadoParada.EN_CAMINO, eta.estado(jornada, segura));
        jornada.setEstado(EstadoJornada.TERMINADA);
        assertEquals(EtaService.EstadoParada.SIN_SERVICIO_HOY, eta.estado(jornada, segura));
    }

    @Test
    void diasDeLaRuta() {
        ruta.setDiasSemana("2,4");
        assertTrue(ruta.seHaceEl(java.time.DayOfWeek.THURSDAY));
        assertFalse(ruta.seHaceEl(java.time.DayOfWeek.MONDAY));
    }
}
