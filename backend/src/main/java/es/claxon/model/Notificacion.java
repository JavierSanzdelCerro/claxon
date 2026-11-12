package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Registro de cada aviso enviado. Sirve para tres cosas:
 * no repetir avisos por la misma llegada (RNF5), mostrar el historial en la app
 * y saber si el vecino lo vio (HU9).
 */
@Entity
@Table(name = "notificacion", indexes = {
        @Index(name = "idx_notif_usuario", columnList = "usuario_id, enviada_en"),
        @Index(name = "idx_notif_llegada", columnList = "jornada_id, parada_id, usuario_id")
})
@Getter @Setter @NoArgsConstructor
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    /** Si se envía a un familiar, el vecino al que se refiere. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "para_vecino_id")
    private Usuario paraVecino;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TipoNotificacion tipo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "jornada_id")
    private Jornada jornada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parada_id")
    private Parada parada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aviso_id")
    private Aviso aviso;

    /** Hora estimada de llegada que se comunicó en este aviso. */
    @Column(name = "eta_avisada")
    private LocalDateTime etaAvisada;

    @Column(nullable = false, length = 120)
    private String titulo;

    @Column(nullable = false, length = 300)
    private String texto;

    @Column(name = "enviada_en", nullable = false)
    private LocalDateTime enviadaEn;

    @Column(name = "vista_en")
    private LocalDateTime vistaEn;
}
