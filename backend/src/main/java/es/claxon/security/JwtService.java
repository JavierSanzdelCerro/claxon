package es.claxon.security;

import es.claxon.model.Usuario;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey clave;
    private final Duration duracion;

    public JwtService(@Value("${claxon.jwt.secreto}") String secreto,
                      @Value("${claxon.jwt.dias:30}") long dias) {
        if (secreto.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("claxon.jwt.secreto debe tener al menos 32 caracteres");
        }
        this.clave = Keys.hmacShaKeyFor(secreto.getBytes(StandardCharsets.UTF_8));
        // Sesión larga: las personas mayores no deben tener que volver a iniciar sesión.
        this.duracion = Duration.ofDays(dias);
    }

    public String generar(Usuario u) {
        Instant ahora = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(u.getId()))
                .claim("rol", u.getRol().name())
                .issuedAt(Date.from(ahora))
                .expiration(Date.from(ahora.plus(duracion)))
                .signWith(clave)
                .compact();
    }

    /** Devuelve el id de usuario si el token es válido; lanza excepción si no. */
    public Long validar(String token) {
        Claims claims = Jwts.parser().verifyWith(clave).build().parseSignedClaims(token).getPayload();
        return Long.valueOf(claims.getSubject());
    }
}
