package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.security.Sesion;
import es.claxon.service.FamiliaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/familia")
public class FamiliaController {

    private final FamiliaService familia;
    private final Sesion sesion;

    public FamiliaController(FamiliaService familia, Sesion sesion) {
        this.familia = familia;
        this.sesion = sesion;
    }

    @GetMapping("/vecinos")
    public List<VecinoVinculadoDto> vecinos() {
        return familia.misVecinos(sesion.usuario());
    }

    @PostMapping("/vincular")
    public VecinoVinculadoDto vincular(@Valid @RequestBody VincularRequest req) {
        return familia.vincular(sesion.usuario(), req.codigo());
    }

    @DeleteMapping("/vecinos/{vecinoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void desvincular(@PathVariable Long vecinoId) {
        familia.desvincular(sesion.usuario(), vecinoId);
    }

    @GetMapping("/vecinos/{vecinoId}/hoy")
    public HoyDto hoy(@PathVariable Long vecinoId) {
        return familia.hoyDe(sesion.usuario(), vecinoId);
    }

    @GetMapping("/vecinos/{vecinoId}/avisos")
    public List<NotificacionDto> avisos(@PathVariable Long vecinoId) {
        return familia.avisosDe(sesion.usuario(), vecinoId);
    }
}
