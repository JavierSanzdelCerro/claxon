package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Un día concreto de una ruta. La hora estimada de cada parada NO se guarda:
 * se calcula con horaInicio + parada.minDesdeSalida + retrasoMin (ver EtaService).
 */
@Entity
@Table(name = "jornada",
       uniqueConstraints = @UniqueConstraint(columnNames = {"ruta_id", "fecha"}))
@Getter @Setter @NoArgsConstructor
public class Jornada {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "ruta_id")
    private Ruta ruta;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(name = "hora_inicio")
    private LocalTime horaInicio;

    /** Orden de la última parada en la que el vendedor pulsó «He llegado» (0 = aún ninguna). */
    @Column(name = "parada_actual", nullable = false)
    private int paradaActual = 0;

    /** Retraso acumulado en minutos (puede ser negativo si va adelantado), medido en el último «He llegado». */
    @Column(name = "retraso_min", nullable = false)
    private int retrasoMin = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoJornada estado = EstadoJornada.PREVISTA;
}
