package es.claxon.repository;

import es.claxon.model.Pueblo;
import es.claxon.model.Suscripcion;
import es.claxon.model.TipoServicio;
import es.claxon.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SuscripcionRepository extends JpaRepository<Suscripcion, Long> {
    List<Suscripcion> findByUsuario(Usuario usuario);
    List<Suscripcion> findByPuebloAndTipo(Pueblo pueblo, TipoServicio tipo);
    Optional<Suscripcion> findByUsuarioAndPuebloAndTipo(Usuario usuario, Pueblo pueblo, TipoServicio tipo);
    List<Suscripcion> findByPueblo(Pueblo pueblo);

    @org.springframework.data.jpa.repository.Query(
            "select count(distinct s.usuario) from Suscripcion s where s.pueblo = :pueblo")
    long contarVecinosSuscritos(Pueblo pueblo);
}
