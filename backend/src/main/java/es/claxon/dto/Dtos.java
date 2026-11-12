package es.claxon.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import es.claxon.model.*;
import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * Objetos que viajan por la API. Se usan records para que sean inmutables
 * y no exponer nunca las entidades JPA (ni el hash de la contraseña).
 */
public final class Dtos {

    private Dtos() {}

    // ---------- Autenticación y perfil ----------

    public record LoginRequest(@NotBlank String username, @NotBlank String password) {}

    public record RegistroRequest(
            @NotBlank @Size(min = 3, max = 60) String username,
            @NotBlank @Size(min = 6, max = 100) String password,
            @NotBlank @Size(max = 100) String nombre,
            @Size(max = 20) String telefono,
            @NotNull Rol rol,
            Long puebloId) {}

    public record LoginResponse(String token, UsuarioDto usuario) {}

    public record UsuarioDto(Long id, String username, String nombre, String telefono, Rol rol,
                             PuebloDto pueblo, boolean textoGrande, String codigoVinculo,
                             VendedorDto vendedor) {
        public static UsuarioDto de(Usuario u, Vendedor v) {
            return new UsuarioDto(u.getId(), u.getUsername(), u.getNombre(), u.getTelefono(), u.getRol(),
                    u.getPueblo() == null ? null : PuebloDto.de(u.getPueblo()), u.isTextoGrande(),
                    u.getCodigoVinculo(), v == null ? null : VendedorDto.de(v));
        }
    }

    public record PerfilRequest(@Size(max = 100) String nombre, @Size(max = 20) String telefono,
                                Long puebloId, Boolean textoGrande) {}

    public record TokenFcmRequest(@NotBlank String token) {}

    public record NuevoUsuarioRequest(
            @NotBlank @Size(min = 3, max = 60) String username,
            @NotBlank @Size(min = 6) String password,
            @NotBlank String nombre,
            String telefono,
            @NotNull Rol rol,
            Long puebloId,
            String nombreComercial,
            TipoServicio tipo) {}

    // ---------- Pueblos y servicios ----------

    public record PuebloDto(Long id, String nombre, String codIne, String comarca, Integer habitantes) {
        public static PuebloDto de(Pueblo p) {
            return new PuebloDto(p.getId(), p.getNombre(), p.getCodIne(), p.getComarca(), p.getHabitantes());
        }
    }

    public record VendedorDto(Long id, String nombreComercial, TipoServicio tipo, String tipoEtiqueta) {
        public static VendedorDto de(Vendedor v) {
            return new VendedorDto(v.getId(), v.getNombreComercial(), v.getTipo(), v.getTipo().getEtiqueta());
        }
    }

    /** Una parada a la que se le puede hacer un encargo. */
    public record ParadaEncargableDto(Long paradaId, String lugar, String vendedor, TipoServicio tipo,
                                      String tipoEtiqueta, String rutaNombre, String dias,
                                      @JsonFormat(pattern = "HH:mm") LocalTime horaHabitual,
                                      List<LocalDate> proximosDias) {}

    public record ServicioDto(TipoServicio tipo, String etiqueta) {}

    // ---------- Pantalla «Hoy» ----------

    public record PasoDto(Long rutaId, Long paradaId, String vendedor, TipoServicio tipo, String tipoEtiqueta,
                          String lugar, @JsonFormat(pattern = "HH:mm") LocalTime hora, String estado,
                          Long minutosFaltan, int retrasoMin, boolean iniciada) {}

    public record MedicoDto(String estado, String texto,
                            @JsonFormat(pattern = "HH:mm") LocalTime horaInicio,
                            @JsonFormat(pattern = "HH:mm") LocalTime horaFin) {}

    public record HoyDto(PuebloDto pueblo, LocalDate fecha,
                         @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss") LocalDateTime actualizado,
                         List<PasoDto> pasos, MedicoDto medico, List<AvisoDto> cambios,
                         List<AvisoDto> consultasSemana) {}

    // ---------- Suscripciones ----------

    public record SuscripcionDto(Long id, PuebloDto pueblo, TipoServicio tipo, String tipoEtiqueta, int minAntes) {
        public static SuscripcionDto de(Suscripcion s) {
            return new SuscripcionDto(s.getId(), PuebloDto.de(s.getPueblo()), s.getTipo(), s.getTipo().getEtiqueta(), s.getMinAntes());
        }
    }

    public record SuscripcionRequest(@NotNull Long puebloId, @NotNull TipoServicio tipo,
                                     @Min(5) @Max(60) Integer minAntes, Long vecinoId) {}

    // ---------- Encargos ----------

    public record EncargoRequest(@NotNull Long paradaId, @NotNull LocalDate fecha,
                                 @NotBlank @Size(max = 300) String texto,
                                 Long vecinoId, @Size(max = 40) String idCliente) {}

    public record EncargoDto(Long id, LocalDate fecha, String texto, EstadoEncargo estado,
                             Long paradaId, String lugar, String pueblo, String vendedor, String tipoEtiqueta,
                             String vecino, String telefonoVecino, String hechoPor, String idCliente) {
        public static EncargoDto de(Encargo e) {
            Parada p = e.getParada();
            Vendedor v = p.getRuta().getVendedor();
            return new EncargoDto(e.getId(), e.getFecha(), e.getTexto(), e.getEstado(), p.getId(), p.getLugar(),
                    p.getPueblo().getNombre(), v.getNombreComercial(), v.getTipo().getEtiqueta(),
                    e.getUsuario().getNombre(), e.getUsuario().getTelefono(),
                    e.getCreadoPor() == null ? null : e.getCreadoPor().getNombre(), e.getIdCliente());
        }
    }

    // ---------- Notificaciones ----------

    public record NotificacionDto(Long id, TipoNotificacion tipo, String titulo, String texto,
                                  @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss") LocalDateTime enviadaEn,
                                  @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss") LocalDateTime vistaEn,
                                  String paraVecino) {
        public static NotificacionDto de(Notificacion n) {
            return new NotificacionDto(n.getId(), n.getTipo(), n.getTitulo(), n.getTexto(), n.getEnviadaEn(),
                    n.getVistaEn(), n.getParaVecino() == null ? null : n.getParaVecino().getNombre());
        }
    }

    // ---------- Familia ----------

    public record VincularRequest(@NotBlank @Pattern(regexp = "\\d{6}", message = "son 6 cifras") String codigo) {}

    public record VecinoVinculadoDto(Long id, String nombre, String telefono, PuebloDto pueblo, boolean puedeEncargar,
                                     NotificacionDto ultimoAviso) {}

    // ---------- Vendedor ----------

    public record ParadaRequest(Long id, @NotNull Long puebloId, @NotBlank @Size(max = 100) String lugar,
                                @NotNull @Min(0) @Max(720) Integer minDesdeSalida) {}

    public record RutaRequest(@NotBlank @Size(max = 100) String nombre,
                              @NotBlank @Pattern(regexp = "[1-7](,[1-7])*", message = "días del 1 (lunes) al 7 (domingo) separados por comas") String diasSemana,
                              @JsonFormat(pattern = "HH:mm") LocalTime horaSalidaHabitual,
                              Boolean activa,
                              @NotEmpty List<ParadaRequest> paradas) {}

    public record ParadaDto(Long id, int orden, PuebloDto pueblo, String lugar, int minDesdeSalida) {
        public static ParadaDto de(Parada p) {
            return new ParadaDto(p.getId(), p.getOrden(), PuebloDto.de(p.getPueblo()), p.getLugar(), p.getMinDesdeSalida());
        }
    }

    public record RutaDto(Long id, String nombre, String diasSemana,
                          @JsonFormat(pattern = "HH:mm") LocalTime horaSalidaHabitual,
                          boolean activa, List<ParadaDto> paradas) {
        public static RutaDto de(Ruta r) {
            return new RutaDto(r.getId(), r.getNombre(), r.getDiasSemana(), r.getHoraSalidaHabitual(), r.isActiva(),
                    r.getParadas().stream().map(ParadaDto::de).toList());
        }
    }

    public record ParadaHoyDto(Long paradaId, int orden, String pueblo, String lugar,
                               @JsonFormat(pattern = "HH:mm") LocalTime hora, String estado,
                               int encargosPendientes, int encargosTotales) {}

    public record RutaHoyDto(Long rutaId, String nombre, boolean tocaHoy, String estadoJornada,
                             @JsonFormat(pattern = "HH:mm") LocalTime horaInicio,
                             @JsonFormat(pattern = "HH:mm") LocalTime horaSalidaHabitual,
                             int retrasoMin, List<ParadaHoyDto> paradas) {}

    public record EncargosParadaDto(Long paradaId, int orden, String pueblo, String lugar,
                                    @JsonFormat(pattern = "HH:mm") LocalTime hora,
                                    List<EncargoDto> encargos) {}

    public record SemanaDto(LocalDate lunes, long encargos, long entregados, long cancelados) {}

    // ---------- Ayuntamiento ----------

    public record AvisoRequest(@NotNull TipoAviso tipo, @NotNull LocalDate fecha,
                               @JsonFormat(pattern = "HH:mm") LocalTime horaInicio,
                               @JsonFormat(pattern = "HH:mm") LocalTime horaFin,
                               @Size(max = 300) String texto) {}

    public record AvisoDto(Long id, TipoAviso tipo, LocalDate fecha,
                           @JsonFormat(pattern = "HH:mm") LocalTime horaInicio,
                           @JsonFormat(pattern = "HH:mm") LocalTime horaFin,
                           String texto, String resumen,
                           @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss") LocalDateTime creadoEn) {}

    public record PanelDto(PuebloDto pueblo, long vecinosSuscritos, HoyDto hoy, List<AvisoDto> proximos) {}

    public record PublicadoDto(AvisoDto aviso, int avisados) {}

    // ---------- Demo ----------

    public record RelojDto(@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss") LocalDateTime ahora, long desfaseMin) {}
}
