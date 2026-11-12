package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.security.Sesion;
import es.claxon.service.VendedorService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/vendedor")
public class VendedorController {

    private final VendedorService vendedor;
    private final Sesion sesion;

    public VendedorController(VendedorService vendedor, Sesion sesion) {
        this.vendedor = vendedor;
        this.sesion = sesion;
    }

    @GetMapping("/rutas")
    public List<RutaDto> rutas() {
        return vendedor.misRutas(sesion.usuario());
    }

    @PostMapping("/rutas")
    @ResponseStatus(HttpStatus.CREATED)
    public RutaDto crear(@Valid @RequestBody RutaRequest req) {
        return vendedor.crearRuta(sesion.usuario(), req);
    }

    @PutMapping("/rutas/{id}")
    public RutaDto editar(@PathVariable Long id, @Valid @RequestBody RutaRequest req) {
        return vendedor.editarRuta(sesion.usuario(), id, req);
    }

    @DeleteMapping("/rutas/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void borrar(@PathVariable Long id) {
        vendedor.borrarRuta(sesion.usuario(), id);
    }

    @GetMapping("/hoy")
    public List<RutaHoyDto> hoy() {
        return vendedor.hoy(sesion.usuario());
    }

    @PostMapping("/rutas/{id}/iniciar")
    public RutaHoyDto iniciar(@PathVariable Long id) {
        return vendedor.iniciar(sesion.usuario(), id);
    }

    @PostMapping("/rutas/{id}/llegado")
    public RutaHoyDto llegado(@PathVariable Long id, @RequestParam(required = false) Long paradaId) {
        return vendedor.heLlegado(sesion.usuario(), id, paradaId);
    }

    @PostMapping("/rutas/{id}/terminar")
    public RutaHoyDto terminar(@PathVariable Long id) {
        return vendedor.terminar(sesion.usuario(), id);
    }

    @GetMapping("/rutas/{id}/encargos")
    public List<EncargosParadaDto> encargos(@PathVariable Long id,
                                            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        return vendedor.encargosPorParada(sesion.usuario(), id, fecha);
    }

    @PostMapping("/encargos/{id}/entregado")
    public EncargoDto entregado(@PathVariable Long id, @RequestParam(defaultValue = "true") boolean valor) {
        return vendedor.entregar(sesion.usuario(), id, valor);
    }

    @GetMapping("/estadisticas")
    public List<SemanaDto> estadisticas() {
        return vendedor.estadisticas(sesion.usuario());
    }
}
