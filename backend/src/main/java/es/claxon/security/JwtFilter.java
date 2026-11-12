package es.claxon.security;

import es.claxon.repository.UsuarioRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtService jwt;
    private final UsuarioRepository usuarios;

    public JwtFilter(JwtService jwt, UsuarioRepository usuarios) {
        this.jwt = jwt;
        this.usuarios = usuarios;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String cabecera = req.getHeader("Authorization");
        if (cabecera != null && cabecera.startsWith("Bearer ")) {
            try {
                Long id = jwt.validar(cabecera.substring(7));
                usuarios.findById(id).ifPresent(u -> {
                    UsuarioActual actual = UsuarioActual.de(u);
                    var auth = new UsernamePasswordAuthenticationToken(actual, null, actual.autoridades());
                    SecurityContextHolder.getContext().setAuthentication(auth);
                });
            } catch (Exception e) {
                // Token caducado o manipulado: se sigue como anónimo y la regla de seguridad responderá 401.
                SecurityContextHolder.clearContext();
            }
        }
        chain.doFilter(req, res);
    }
}
