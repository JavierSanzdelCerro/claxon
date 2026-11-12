package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.dto.Dtos.*;
import es.claxon.model.Pueblo;
import es.claxon.model.Suscripcion;
import es.claxon.model.Usuario;
import es.claxon.repository.PuebloRepository;
import es.claxon.repository.SuscripcionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Suscribirse a los servicios de un pueblo (RF2). */
@Service
public class SuscripcionService {

    private final SuscripcionRepository suscripciones;
    private final PuebloRepository pueblos;
    private final Permisos permisos;

    public SuscripcionService(SuscripcionRepository suscripciones, PuebloRepository pueblos, Permisos permisos) {
        this.suscripciones = suscripciones;
        this.pueblos = pueblos;
        this.permisos = permisos;
    }

    @Transactional(readOnly = true)
    public List<SuscripcionDto> listar(Usuario actual, Long vecinoId) {
        Usuario u = permisos.vecinoObjetivo(actual, vecinoId);
        return suscripciones.findByUsuario(u).stream().map(SuscripcionDto::de).toList();
    }

    @Transactional
    public SuscripcionDto suscribir(Usuario actual, SuscripcionRequest req) {
        Usuario u = permisos.vecinoObjetivo(actual, req.vecinoId());
        Pueblo p = pueblos.findById(req.puebloId()).orElseThrow(() -> ApiException.noEncontrado("Pueblo"));
        Suscripcion s = suscripciones.findByUsuarioAndPuebloAndTipo(u, p, req.tipo()).orElseGet(Suscripcion::new);
        s.setUsuario(u);
        s.setPueblo(p);
        s.setTipo(req.tipo());
        s.setMinAntes(req.minAntes() == null ? 15 : req.minAntes());
        return SuscripcionDto.de(suscripciones.save(s));
    }

    @Transactional
    public void borrar(Usuario actual, Long id) {
        Suscripcion s = suscripciones.findById(id).orElseThrow(() -> ApiException.noEncontrado("Suscripción"));
        // Comprueba que es suya o de un vecino vinculado.
        permisos.vecinoObjetivo(actual, s.getUsuario().getId());
        suscripciones.delete(s);
    }
}
