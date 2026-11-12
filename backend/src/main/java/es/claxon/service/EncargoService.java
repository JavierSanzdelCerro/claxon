package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.*;
import es.claxon.repository.EncargoRepository;
import es.claxon.repository.ParadaRepository;
import es.claxon.repository.PuebloRepository;
import es.claxon.repository.RutaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** Encargos del vecino (RF6) y paradas a las que se puede encargar. */
@Service
public class EncargoService {

    /** Días hacia delante en los que se admiten encargos. */
    private static final int DIAS_MAX = 14;

    private final EncargoRepository encargos;
    private final ParadaRepository paradas;
    private final PuebloRepository pueblos;
    private final RutaRepository rutas;
    private final Permisos permisos;
    private final RelojClaxon reloj;

    public EncargoService(EncargoRepository encargos, ParadaRepository paradas, PuebloRepository pueblos,
                          RutaRepository rutas, Permisos permisos, RelojClaxon reloj) {
        this.encargos = encargos;
        this.paradas = paradas;
        this.pueblos = pueblos;
        this.rutas = rutas;
        this.permisos = permisos;
        this.reloj = reloj;
    }

    /** Vendedores que paran en el pueblo, con los próximos días en que pasan. */
    @Transactional(readOnly = true)
    public List<ParadaEncargableDto> paradasDe(Long puebloId) {
        Pueblo pueblo = pueblos.findById(puebloId).orElseThrow(() -> ApiException.noEncontrado("Pueblo"));
        LocalDate hoy = reloj.hoy();
        List<ParadaEncargableDto> res = new ArrayList<>();
        for (Parada p : paradas.findByPueblo(pueblo)) {
            Ruta r = p.getRuta();
            if (!r.isActiva()) continue;
            List<LocalDate> proximos = new ArrayList<>();
            for (int i = 0; i <= DIAS_MAX && proximos.size() < 4; i++) {
                LocalDate d = hoy.plusDays(i);
                if (r.seHaceEl(d.getDayOfWeek())) proximos.add(d);
            }
            Vendedor v = r.getVendedor();
            res.add(new ParadaEncargableDto(p.getId(), p.getLugar(), v.getNombreComercial(), v.getTipo(),
                    v.getTipo().getEtiqueta(), r.getNombre(), r.getDiasSemana(), r.getHoraSalidaHabitual() == null ? null
                    : r.getHoraSalidaHabitual().plusMinutes(p.getMinDesdeSalida()), proximos));
        }
        res.sort(Comparator.comparing(ParadaEncargableDto::vendedor));
        return res;
    }

    @Transactional(readOnly = true)
    public List<EncargoDto> misEncargos(Usuario actual, Long vecinoId) {
        Usuario u = permisos.vecinoObjetivo(actual, vecinoId);
        return encargos.findDelVecinoDesde(u, reloj.hoy().minusDays(7)).stream().map(EncargoDto::de).toList();
    }

    @Transactional
    public EncargoDto crear(Usuario actual, EncargoRequest req) {
        // Si el móvil reenvía un encargo que ya llegó (por ejemplo, tras perder la red), se devuelve el mismo.
        if (req.idCliente() != null && !req.idCliente().isBlank()) {
            var existente = encargos.findByIdCliente(req.idCliente());
            if (existente.isPresent()) return EncargoDto.de(existente.get());
        }
        Usuario vecino = permisos.vecinoParaEncargar(actual, req.vecinoId());
        Parada p = paradas.findById(req.paradaId()).orElseThrow(() -> ApiException.noEncontrado("Parada"));
        LocalDate hoy = reloj.hoy();
        if (req.fecha().isBefore(hoy)) throw ApiException.invalido("Ese día ya ha pasado");
        if (req.fecha().isAfter(hoy.plusDays(DIAS_MAX))) throw ApiException.invalido("Solo se puede encargar para las próximas dos semanas");
        if (!p.getRuta().seHaceEl(req.fecha().getDayOfWeek())) throw ApiException.invalido("Ese día no pasa por tu pueblo");

        Encargo e = new Encargo();
        e.setUsuario(vecino);
        e.setCreadoPor(vecino.getId().equals(actual.getId()) ? null : actual);
        e.setParada(p);
        e.setFecha(req.fecha());
        e.setTexto(req.texto().trim());
        e.setIdCliente(req.idCliente() == null || req.idCliente().isBlank() ? null : req.idCliente());
        e.setCreadoEn(reloj.ahora());
        return EncargoDto.de(encargos.save(e));
    }

    @Transactional
    public EncargoDto cancelar(Usuario actual, Long id) {
        Encargo e = encargos.findById(id).orElseThrow(() -> ApiException.noEncontrado("Encargo"));
        permisos.vecinoParaEncargar(actual, e.getUsuario().getId());
        if (e.getEstado() != EstadoEncargo.PENDIENTE) throw ApiException.invalido("Este encargo ya no se puede cancelar");
        e.setEstado(EstadoEncargo.CANCELADO);
        return EncargoDto.de(e);
    }
}
