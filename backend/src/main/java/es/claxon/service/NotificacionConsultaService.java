package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.NotificacionDto;
import es.claxon.model.Notificacion;
import es.claxon.model.Usuario;
import es.claxon.repository.NotificacionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/** Bandeja de avisos del usuario. La app la consulta para mostrar avisos aunque no haya Firebase. */
@Service
public class NotificacionConsultaService {

    private final NotificacionRepository notificaciones;
    private final RelojClaxon reloj;

    public NotificacionConsultaService(NotificacionRepository notificaciones, RelojClaxon reloj) {
        this.notificaciones = notificaciones;
        this.reloj = reloj;
    }

    @Transactional(readOnly = true)
    public List<NotificacionDto> mias(Usuario u, LocalDateTime desde) {
        List<Notificacion> lista = desde == null
                ? notificaciones.findTop50ByUsuarioOrderByEnviadaEnDesc(u)
                : notificaciones.findByUsuarioAndEnviadaEnAfterOrderByEnviadaEnDesc(u, desde);
        return lista.stream().map(NotificacionDto::de).toList();
    }

    /** El vecino ha visto el aviso (HU9): se guarda la primera vez. */
    @Transactional
    public NotificacionDto marcarVista(Usuario u, Long id) {
        Notificacion n = notificaciones.findById(id).orElseThrow(() -> ApiException.noEncontrado("Aviso"));
        if (!n.getUsuario().getId().equals(u.getId())) throw ApiException.prohibido();
        if (n.getVistaEn() == null) n.setVistaEn(reloj.ahora());
        return NotificacionDto.de(n);
    }
}
