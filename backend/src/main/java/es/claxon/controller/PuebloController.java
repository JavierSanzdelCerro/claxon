package es.claxon.controller;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.TipoServicio;
import es.claxon.repository.PuebloRepository;
import es.claxon.service.EncargoService;
import es.claxon.service.HoyService;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

/** Datos públicos: pueblos, lo que pasa hoy y los servicios. También alimenta el tablón del bar (RF13). */
@RestController
@RequestMapping("/api")
public class PuebloController {

    private final PuebloRepository pueblos;
    private final HoyService hoy;
    private final EncargoService encargos;
    private final RelojClaxon reloj;

    public PuebloController(PuebloRepository pueblos, HoyService hoy, EncargoService encargos, RelojClaxon reloj) {
        this.pueblos = pueblos;
        this.hoy = hoy;
        this.encargos = encargos;
        this.reloj = reloj;
    }

    @GetMapping("/pueblos")
    public List<PuebloDto> buscar(@RequestParam(required = false) String q) {
        var lista = q == null || q.isBlank() ? pueblos.findAllByOrderByNombreAsc()
                : pueblos.findByNombreContainingIgnoreCaseOrderByNombreAsc(q.trim());
        return lista.stream().map(PuebloDto::de).toList();
    }

    @GetMapping("/pueblos/{id}")
    public PuebloDto uno(@PathVariable Long id) {
        return PuebloDto.de(pueblos.findById(id).orElseThrow(() -> ApiException.noEncontrado("Pueblo")));
    }

    @GetMapping("/pueblos/{id}/hoy")
    public HoyDto hoy(@PathVariable Long id) {
        return hoy.de(pueblos.findById(id).orElseThrow(() -> ApiException.noEncontrado("Pueblo")), reloj.hoy());
    }

    @GetMapping("/pueblos/{id}/paradas")
    public List<ParadaEncargableDto> paradas(@PathVariable Long id) {
        return encargos.paradasDe(id);
    }

    /** Tablón del bar: misma información que «Hoy», sin iniciar sesión. */
    @GetMapping("/public/tablon/{puebloId}")
    public HoyDto tablon(@PathVariable Long puebloId) {
        return hoy(puebloId);
    }

    @GetMapping("/public/servicios")
    public List<ServicioDto> servicios() {
        return Arrays.stream(TipoServicio.values()).map(t -> new ServicioDto(t, t.getEtiqueta())).toList();
    }
}
