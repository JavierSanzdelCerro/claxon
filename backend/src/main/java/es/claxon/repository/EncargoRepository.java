package es.claxon.repository;

import es.claxon.model.Encargo;
import es.claxon.model.EstadoEncargo;
import es.claxon.model.Ruta;
import es.claxon.model.Usuario;
import es.claxon.model.Vendedor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface EncargoRepository extends JpaRepository<Encargo, Long> {

    @Query("select e from Encargo e where e.usuario = :usuario and e.fecha >= :desde order by e.fecha, e.creadoEn")
    List<Encargo> findDelVecinoDesde(Usuario usuario, LocalDate desde);

    @Query("select e from Encargo e where e.parada.ruta = :ruta and e.fecha = :fecha and e.estado <> es.claxon.model.EstadoEncargo.CANCELADO order by e.parada.orden, e.creadoEn")
    List<Encargo> findDeRutaYFecha(Ruta ruta, LocalDate fecha);

    @Query("select e from Encargo e where e.parada.ruta.vendedor = :vendedor and e.fecha between :desde and :hasta")
    List<Encargo> findDeVendedorEntre(Vendedor vendedor, LocalDate desde, LocalDate hasta);

    long countByParadaIdAndFechaAndEstado(Long paradaId, LocalDate fecha, EstadoEncargo estado);

    Optional<Encargo> findByIdCliente(String idCliente);

    boolean existsByParadaId(Long paradaId);
}
