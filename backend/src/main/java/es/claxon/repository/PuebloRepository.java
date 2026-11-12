package es.claxon.repository;

import es.claxon.model.Pueblo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PuebloRepository extends JpaRepository<Pueblo, Long> {
    Optional<Pueblo> findByCodIne(String codIne);
    List<Pueblo> findAllByOrderByNombreAsc();
    List<Pueblo> findByNombreContainingIgnoreCaseOrderByNombreAsc(String texto);
}
