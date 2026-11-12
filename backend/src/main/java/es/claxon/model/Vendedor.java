package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "vendedor")
@Getter @Setter @NoArgsConstructor
public class Vendedor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", unique = true)
    private Usuario usuario;

    @Column(name = "nombre_comercial", nullable = false, length = 100)
    private String nombreComercial;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TipoServicio tipo;
}
