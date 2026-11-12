package es.claxon.security;

import es.claxon.model.Rol;
import es.claxon.model.Usuario;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collection;
import java.util.List;

/** Lo que guarda Spring Security del usuario autenticado. */
public record UsuarioActual(Long id, Rol rol) {

    public Collection<? extends GrantedAuthority> autoridades() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + rol.name()));
    }

    public static UsuarioActual de(Usuario u) {
        return new UsuarioActual(u.getId(), u.getRol());
    }
}
