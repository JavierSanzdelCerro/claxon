package es.claxon.controller;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.RelojDto;
import es.claxon.service.NotificacionService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;

/**
 * Solo para la demostración (claxon.demo=true): permite adelantar el reloj del servidor
 * para enseñar el aviso de 15 minutos sin tener que esperar. En producción responde 404.
 */
@RestController
@RequestMapping("/api/public/demo")
public class DemoController {

    private final RelojClaxon reloj;
    private final NotificacionService notificaciones;
    private final boolean demo;

    public DemoController(RelojClaxon reloj, NotificacionService notificaciones,
                          @Value("${claxon.demo:false}") boolean demo) {
        this.reloj = reloj;
        this.notificaciones = notificaciones;
        this.demo = demo;
    }

    @GetMapping("/reloj")
    public RelojDto reloj() {
        comprobar();
        return new RelojDto(reloj.ahora(), reloj.getDesfase().toMinutes());
    }

    /** minutos > 0 adelanta; minutos = 0 vuelve a la hora real. */
    @PostMapping("/reloj")
    public RelojDto adelantar(@RequestParam int minutos) {
        comprobar();
        if (minutos < 0 || minutos > 24 * 60) throw ApiException.invalido("Minutos entre 0 y 1440");
        reloj.setDesfase(minutos == 0 ? Duration.ZERO : reloj.getDesfase().plusMinutes(minutos));
        notificaciones.revisarLlegadas();
        return reloj();
    }

    private void comprobar() {
        if (!demo) throw new ApiException(HttpStatus.NOT_FOUND, "No disponible");
    }
}
