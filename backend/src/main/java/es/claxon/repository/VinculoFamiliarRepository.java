package es.claxon.repository;

import es.claxon.model.Usuario;
import es.claxon.model.VinculoFamiliar;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VinculoFamiliarRepository extends JpaRepository<VinculoFamiliar, Long> {
    List<VinculoFamiliar> findByFamiliar(Usuario familiar);
    List<VinculoFamiliar> findByVecino(Usuario vecino);
    Optional<VinculoFamiliar> findByFamiliarAndVecino(Usuario familiar, Usuario vecino);
}
