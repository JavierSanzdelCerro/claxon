package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "parada")
@Getter @Setter @NoArgsConstructor
public class Parada {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "ruta_id")
    private Ruta ruta;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "pueblo_id")
    private Pueblo pueblo;

    /** Posición en la ruta, empezando en 1. */
    @Column(nullable = false)
    private int orden;

    /** Sitio concreto del pueblo: "Plaza", "Junto a la iglesia"... */
    @Column(nullable = false, length = 100)
    private String lugar = "Plaza";

    /** Minutos desde la salida hasta llegar a esta parada. */
    @Column(name = "min_desde_salida", nullable = false)
    private int minDesdeSalida;
}
