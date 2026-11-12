package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Entity
@Table(name = "ruta")
@Getter @Setter @NoArgsConstructor
public class Ruta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "vendedor_id")
    private Vendedor vendedor;

    @Column(nullable = false, length = 100)
    private String nombre;

    /** Días en que se hace la ruta, como números ISO separados por comas: "2,4" = martes y jueves. */
    @Column(name = "dias_semana", nullable = false, length = 20)
    private String diasSemana = "1,2,3,4,5,6";

    /** Hora de salida habitual: se usa para mostrar el horario previsto y si el vendedor se queda sin red. */
    @Column(name = "hora_salida_habitual")
    private LocalTime horaSalidaHabitual;

    @Column(nullable = false)
    private boolean activa = true;

    @OneToMany(mappedBy = "ruta", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("orden ASC")
    private List<Parada> paradas = new ArrayList<>();

    public Set<DayOfWeek> dias() {
        if (diasSemana == null || diasSemana.isBlank()) return Set.of();
        return Arrays.stream(diasSemana.split(","))
                .map(String::trim).filter(s -> !s.isEmpty())
                .map(s -> DayOfWeek.of(Integer.parseInt(s)))
                .collect(Collectors.toSet());
    }

    public boolean seHaceEl(DayOfWeek dia) {
        return dias().contains(dia);
    }
}
