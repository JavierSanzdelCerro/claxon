package es.claxon.repository;

import es.claxon.model.Jornada;
import es.claxon.model.Notificacion;
import es.claxon.model.Parada;
import es.claxon.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {

    /** Avisos ya enviados a un usuario por una llegada concreta (para no repetir). */
    List<Notificacion> findByUsuarioAndJornadaAndParadaOrderByEnviadaEnAsc(Usuario usuario, Jornada jornada, Parada parada);

    List<Notificacion> findByUsuarioAndEnviadaEnAfterOrderByEnviadaEnDesc(Usuario usuario, LocalDateTime desde);

    List<Notificacion> findTop50ByUsuarioOrderByEnviadaEnDesc(Usuario usuario);

    /** Últimos avisos del vecino (para que el familiar vea si los ha leído). */
    List<Notificacion> findTop20ByUsuarioAndParaVecinoIsNullOrderByEnviadaEnDesc(Usuario vecino);
}
