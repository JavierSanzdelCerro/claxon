package es.claxon.repository;

import es.claxon.model.EstadoJornada;
import es.claxon.model.Jornada;
import es.claxon.model.Ruta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface JornadaRepository extends JpaRepository<Jornada, Long> {
    Optional<Jornada> findByRutaAndFecha(Ruta ruta, LocalDate fecha);
    boolean existsByRuta(Ruta ruta);
    List<Jornada> findByFechaAndEstado(LocalDate fecha, EstadoJornada estado);
}
