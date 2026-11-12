package es.claxon.config;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * Reloj de la aplicación. Envuelve al reloj del sistema y permite adelantarlo
 * (solo en modo demo) para enseñar los avisos sin esperar 25 minutos reales.
 * En los tests se sustituye por un reloj fijo.
 */
public class RelojClaxon extends Clock {

    private volatile Clock base;
    private volatile Duration desfase = Duration.ZERO;

    public RelojClaxon(Clock base) {
        this.base = base;
    }

    @Override public ZoneId getZone() { return base.getZone(); }
    @Override public Clock withZone(ZoneId zone) { return new RelojClaxon(base.withZone(zone)); }
    @Override public Instant instant() { return base.instant().plus(desfase); }

    public LocalDateTime ahora() { return LocalDateTime.now(this).withNano(0); }
    public LocalDate hoy() { return LocalDate.now(this); }

    /** Cambia el reloj de referencia (lo usan los tests para fijar la hora). */
    public void usarReloj(Clock nuevo) { this.base = nuevo; }

    public Duration getDesfase() { return desfase; }
    public void setDesfase(Duration desfase) { this.desfase = desfase == null ? Duration.ZERO : desfase; }
}
