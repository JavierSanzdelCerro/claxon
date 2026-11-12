package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "suscripcion",
       uniqueConstraints = @UniqueConstraint(columnNames = {"usuario_id", "pueblo_id", "tipo"}))
@Getter @Setter @NoArgsConstructor
public class Suscripcion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "pueblo_id")
    private Pueblo pueblo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TipoServicio tipo;

    /** Minutos de antelación del aviso (15 por defecto). */
    @Column(name = "min_antes", nullable = false)
    private int minAntes = 15;
}
