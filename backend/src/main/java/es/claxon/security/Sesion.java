package es.claxon.security;

import es.claxon.config.ApiException;
import es.claxon.model.Usuario;
import es.claxon.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/** Acceso cómodo al usuario que hace la petición. */
@Component
public class Sesion {

    private final UsuarioRepository usuarios;

    public Sesion(UsuarioRepository usuarios) {
        this.usuarios = usuarios;
    }

    public Usuario usuario() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UsuarioActual actual)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Inicia sesión");
        }
        return usuarios.findById(actual.id()).orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Inicia sesión"));
    }
}
