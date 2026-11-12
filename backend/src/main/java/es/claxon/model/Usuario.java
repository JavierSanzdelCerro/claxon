package es.claxon.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "usuario")
@Getter @Setter @NoArgsConstructor
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Nombre de usuario para iniciar sesión (puede ser el teléfono). */
    @Column(nullable = false, unique = true, length = 60)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(length = 20)
    private String telefono;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Rol rol;

    /** Pueblo donde vive el vecino o que gestiona el ayuntamiento. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pueblo_id")
    private Pueblo pueblo;

    @Column(name = "texto_grande", nullable = false)
    private boolean textoGrande = true;

    @Column(name = "token_fcm", length = 300)
    private String tokenFcm;

    /** Código de 6 cifras que el vecino da a su familiar para vincular las cuentas. */
    @Column(name = "codigo_vinculo", unique = true, length = 6)
    private String codigoVinculo;

    @Column(name = "creado_en", nullable = false)
    private LocalDateTime creadoEn = LocalDateTime.now();
}
