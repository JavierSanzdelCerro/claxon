package es.claxon.repository;

import es.claxon.model.Rol;
import es.claxon.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByUsername(String username);
    boolean existsByUsername(String username);
    Optional<Usuario> findByCodigoVinculo(String codigo);
    List<Usuario> findByRolOrderByNombreAsc(Rol rol);
}
