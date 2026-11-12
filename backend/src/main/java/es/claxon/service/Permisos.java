package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.model.Rol;
import es.claxon.model.Usuario;
import es.claxon.model.VinculoFamiliar;
import es.claxon.repository.UsuarioRepository;
import es.claxon.repository.VinculoFamiliarRepository;
import org.springframework.stereotype.Component;

/**
 * Resuelve «para quién» actúa el usuario. Un vecino actúa para sí mismo; un familiar
 * puede actuar en nombre de un vecino vinculado (RF14). Cada uno ve solo lo suyo (RNF6).
 */
@Component
public class Permisos {

    private final UsuarioRepository usuarios;
    private final VinculoFamiliarRepository vinculos;

    public Permisos(UsuarioRepository usuarios, VinculoFamiliarRepository vinculos) {
        this.usuarios = usuarios;
        this.vinculos = vinculos;
    }

    public Usuario vecinoObjetivo(Usuario actual, Long vecinoId) {
        return vinculoObjetivo(actual, vecinoId, false);
    }

    /** Igual que vecinoObjetivo, pero exige que el vínculo permita encargar. */
    public Usuario vecinoParaEncargar(Usuario actual, Long vecinoId) {
        return vinculoObjetivo(actual, vecinoId, true);
    }

    private Usuario vinculoObjetivo(Usuario actual, Long vecinoId, boolean encargar) {
        if (actual.getRol() != Rol.VECINO && actual.getRol() != Rol.FAMILIAR) throw ApiException.prohibido();
        if (vecinoId == null || vecinoId.equals(actual.getId())) {
            if (actual.getRol() == Rol.FAMILIAR && vecinoId == null) {
                throw ApiException.invalido("Indica de qué familiar se trata");
            }
            return actual;
        }
        if (actual.getRol() != Rol.FAMILIAR) throw ApiException.prohibido();
        Usuario vecino = usuarios.findById(vecinoId).orElseThrow(() -> ApiException.noEncontrado("Vecino"));
        VinculoFamiliar v = vinculos.findByFamiliarAndVecino(actual, vecino).orElseThrow(ApiException::prohibido);
        if (encargar && !v.isPuedeEncargar()) throw ApiException.prohibido();
        return vecino;
    }
}
