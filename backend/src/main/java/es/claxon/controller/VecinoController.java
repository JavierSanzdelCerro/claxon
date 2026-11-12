package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.security.Sesion;
import es.claxon.service.EncargoService;
import es.claxon.service.NotificacionConsultaService;
import es.claxon.service.SuscripcionService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Suscripciones, encargos y avisos. Los usan el vecino (para sí mismo) y el familiar
 * (pasando vecinoId del vecino vinculado).
 */
@RestController
@RequestMapping("/api")
public class VecinoController {

    private final SuscripcionService suscripciones;
    private final EncargoService encargos;
    private final NotificacionConsultaService notificaciones;
    private final Sesion sesion;

    public VecinoController(SuscripcionService suscripciones, EncargoService encargos,
                            NotificacionConsultaService notificaciones, Sesion sesion) {
        this.suscripciones = suscripciones;
        this.encargos = encargos;
        this.notificaciones = notificaciones;
        this.sesion = sesion;
    }

    @GetMapping("/suscripciones")
    public List<SuscripcionDto> suscripciones(@RequestParam(required = false) Long vecinoId) {
        return suscripciones.listar(sesion.usuario(), vecinoId);
    }

    @PostMapping("/suscripciones")
    public SuscripcionDto suscribir(@Valid @RequestBody SuscripcionRequest req) {
        return suscripciones.suscribir(sesion.usuario(), req);
    }

    @DeleteMapping("/suscripciones/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void borrarSuscripcion(@PathVariable Long id) {
        suscripciones.borrar(sesion.usuario(), id);
    }

    @GetMapping("/encargos")
    public List<EncargoDto> encargos(@RequestParam(required = false) Long vecinoId) {
        return encargos.misEncargos(sesion.usuario(), vecinoId);
    }

    @PostMapping("/encargos")
    @ResponseStatus(HttpStatus.CREATED)
    public EncargoDto encargar(@Valid @RequestBody EncargoRequest req) {
        return encargos.crear(sesion.usuario(), req);
    }

    @PostMapping("/encargos/{id}/cancelar")
    public EncargoDto cancelar(@PathVariable Long id) {
        return encargos.cancelar(sesion.usuario(), id);
    }

    @GetMapping("/notificaciones")
    public List<NotificacionDto> notificaciones(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde) {
        return notificaciones.mias(sesion.usuario(), desde);
    }

    @PostMapping("/notificaciones/{id}/vista")
    public NotificacionDto vista(@PathVariable Long id) {
        return notificaciones.marcarVista(sesion.usuario(), id);
    }
}
