package es.claxon.repository;

import es.claxon.model.Aviso;
import es.claxon.model.Pueblo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface AvisoRepository extends JpaRepository<Aviso, Long> {
    List<Aviso> findByPuebloAndFechaBetweenOrderByFechaAscHoraInicioAsc(Pueblo pueblo, LocalDate desde, LocalDate hasta);
    List<Aviso> findByPuebloAndFechaOrderByCreadoEnAsc(Pueblo pueblo, LocalDate fecha);
}
