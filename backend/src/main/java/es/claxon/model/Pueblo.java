package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Municipio de Teruel. Los 236 se cargan de datos abiertos (código INE + comarca). */
@Entity
@Table(name = "pueblo")
@Getter @Setter @NoArgsConstructor
public class Pueblo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(name = "cod_ine", nullable = false, unique = true, length = 5)
    private String codIne;

    @Column(length = 60)
    private String comarca;

    private Integer habitantes;

    public Pueblo(String nombre, String codIne, String comarca, Integer habitantes) {
        this.nombre = nombre;
        this.codIne = codIne;
        this.comarca = comarca;
        this.habitantes = habitantes;
    }
}
