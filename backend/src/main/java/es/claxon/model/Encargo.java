package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "encargo")
@Getter @Setter @NoArgsConstructor
public class Encargo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Vecino para quien es el encargo. */
    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    /** Quién lo hizo, si fue un familiar en su nombre. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creado_por_id")
    private Usuario creadoPor;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "parada_id")
    private Parada parada;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(nullable = false, length = 300)
    private String texto;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoEncargo estado = EstadoEncargo.PENDIENTE;

    /** Identificador generado en el móvil para no duplicar encargos que se reenvían al recuperar la red. */
    @Column(name = "id_cliente", unique = true, length = 40)
    private String idCliente;

    @Column(name = "creado_en", nullable = false)
    private LocalDateTime creadoEn = LocalDateTime.now();
}
