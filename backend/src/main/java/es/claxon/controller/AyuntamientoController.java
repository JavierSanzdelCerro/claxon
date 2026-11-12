package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.security.Sesion;
import es.claxon.service.AvisoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ayuntamiento")
public class AyuntamientoController {

    private final AvisoService avisos;
    private final Sesion sesion;

    public AyuntamientoController(AvisoService avisos, Sesion sesion) {
        this.avisos = avisos;
        this.sesion = sesion;
    }

    @GetMapping("/panel")
    public PanelDto panel() {
        return avisos.panel(sesion.usuario());
    }

    @PostMapping("/avisos")
    @ResponseStatus(HttpStatus.CREATED)
    public PublicadoDto publicar(@Valid @RequestBody AvisoRequest req) {
        return avisos.publicar(sesion.usuario(), req);
    }

    @DeleteMapping("/avisos/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void borrar(@PathVariable Long id) {
        avisos.borrar(sesion.usuario(), id);
    }
}
