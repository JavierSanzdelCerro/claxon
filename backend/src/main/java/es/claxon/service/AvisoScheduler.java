package es.claxon.service;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** «El reloj del servidor»: cada minuto mira qué llegadas caen dentro de los próximos 15 minutos. */
@Component
public class AvisoScheduler {

    private final NotificacionService notificaciones;

    public AvisoScheduler(NotificacionService notificaciones) {
        this.notificaciones = notificaciones;
    }

    @Scheduled(cron = "${claxon.avisos.cron:0 * * * * *}")
    public void cadaMinuto() {
        notificaciones.revisarLlegadas();
    }
}
