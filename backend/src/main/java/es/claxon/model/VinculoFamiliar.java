package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Une a quien ayuda (familiar) con a quien se ayuda (vecino). */
@Entity
@Table(name = "vinculo_familiar",
       uniqueConstraints = @UniqueConstraint(columnNames = {"familiar_id", "vecino_id"}))
@Getter @Setter @NoArgsConstructor
public class VinculoFamiliar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "familiar_id")
    private Usuario familiar;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "vecino_id")
    private Usuario vecino;

    @Column(name = "puede_encargar", nullable = false)
    private boolean puedeEncargar = true;
}
