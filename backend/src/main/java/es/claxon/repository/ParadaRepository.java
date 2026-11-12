package es.claxon.repository;

import es.claxon.model.Parada;
import es.claxon.model.Pueblo;
import es.claxon.model.Ruta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ParadaRepository extends JpaRepository<Parada, Long> {
    List<Parada> findByRutaOrderByOrdenAsc(Ruta ruta);
    List<Parada> findByPueblo(Pueblo pueblo);
}
