package es.claxon.repository;

import es.claxon.model.Usuario;
import es.claxon.model.Vendedor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface VendedorRepository extends JpaRepository<Vendedor, Long> {
    Optional<Vendedor> findByUsuario(Usuario usuario);
}
