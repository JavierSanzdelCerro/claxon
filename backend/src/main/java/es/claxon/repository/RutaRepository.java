package es.claxon.repository;

import es.claxon.model.Pueblo;
import es.claxon.model.Ruta;
import es.claxon.model.Vendedor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface RutaRepository extends JpaRepository<Ruta, Long> {
    List<Ruta> findByVendedorOrderByNombreAsc(Vendedor vendedor);

    /** Rutas activas que tienen alguna parada en el pueblo. */
    @Query("select distinct p.ruta from Parada p where p.pueblo = :pueblo and p.ruta.activa = true")
    List<Ruta> findActivasQuePasanPor(Pueblo pueblo);
}
