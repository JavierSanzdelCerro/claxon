package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.config.RelojClaxon;
import es.claxon.dto.Dtos.*;
import es.claxon.model.Rol;
import es.claxon.model.Usuario;
import es.claxon.model.VinculoFamiliar;
import es.claxon.repository.NotificacionRepository;
import es.claxon.repository.UsuarioRepository;
import es.claxon.repository.VinculoFamiliarRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Modo familiar (RF14, HU6) y «vio el aviso» (HU9). */
@Service
public class FamiliaService {

    private final UsuarioRepository usuarios;
    private final VinculoFamiliarRepository vinculos;
    private final NotificacionRepository notificaciones;
    private final Permisos permisos;
    private final HoyService hoy;
    private final RelojClaxon reloj;

    public FamiliaService(UsuarioRepository usuarios, VinculoFamiliarRepository vinculos,
                          NotificacionRepository notificaciones, Permisos permisos, HoyService hoy, RelojClaxon reloj) {
        this.usuarios = usuarios;
        this.vinculos = vinculos;
        this.notificaciones = notificaciones;
        this.permisos = permisos;
        this.hoy = hoy;
        this.reloj = reloj;
    }

    /** El vecino da su código de 6 cifras (lo ve en su perfil) y el familiar lo introduce. */
    @Transactional
    public VecinoVinculadoDto vincular(Usuario familiar, String codigo) {
        Usuario vecino = usuarios.findByCodigoVinculo(codigo)
                .filter(u -> u.getRol() == Rol.VECINO)
                .orElseThrow(() -> ApiException.invalido("Ese código no corresponde a ningún vecino"));
        VinculoFamiliar v = vinculos.findByFamiliarAndVecino(familiar, vecino).orElseGet(() -> {
            VinculoFamiliar nuevo = new VinculoFamiliar();
            nuevo.setFamiliar(familiar);
            nuevo.setVecino(vecino);
            return vinculos.save(nuevo);
        });
        return dto(v);
    }

    @Transactional
    public void desvincular(Usuario familiar, Long vecinoId) {
        Usuario vecino = permisos.vecinoObjetivo(familiar, vecinoId);
        vinculos.findByFamiliarAndVecino(familiar, vecino).ifPresent(vinculos::delete);
    }

    @Transactional(readOnly = true)
    public List<VecinoVinculadoDto> misVecinos(Usuario familiar) {
        return vinculos.findByFamiliar(familiar).stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public HoyDto hoyDe(Usuario familiar, Long vecinoId) {
        Usuario vecino = permisos.vecinoObjetivo(familiar, vecinoId);
        if (vecino.getPueblo() == null) throw ApiException.invalido(vecino.getNombre() + " no tiene pueblo configurado");
        return hoy.de(vecino.getPueblo(), reloj.hoy());
    }

    /** Últimos avisos que recibió el vecino, con la hora en que los vio. */
    @Transactional(readOnly = true)
    public List<NotificacionDto> avisosDe(Usuario familiar, Long vecinoId) {
        Usuario vecino = permisos.vecinoObjetivo(familiar, vecinoId);
        return notificaciones.findTop20ByUsuarioAndParaVecinoIsNullOrderByEnviadaEnDesc(vecino).stream()
                .map(NotificacionDto::de).toList();
    }

    private VecinoVinculadoDto dto(VinculoFamiliar v) {
        Usuario vecino = v.getVecino();
        NotificacionDto ultimo = notificaciones.findTop20ByUsuarioAndParaVecinoIsNullOrderByEnviadaEnDesc(vecino)
                .stream().findFirst().map(NotificacionDto::de).orElse(null);
        return new VecinoVinculadoDto(vecino.getId(), vecino.getNombre(), vecino.getTelefono(),
                vecino.getPueblo() == null ? null : PuebloDto.de(vecino.getPueblo()), v.isPuedeEncargar(), ultimo);
    }
}
