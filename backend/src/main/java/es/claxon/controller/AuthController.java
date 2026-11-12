package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.security.Sesion;
import es.claxon.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class AuthController {

    private final UsuarioService usuarios;
    private final Sesion sesion;

    public AuthController(UsuarioService usuarios, Sesion sesion) {
        this.usuarios = usuarios;
        this.sesion = sesion;
    }

    @PostMapping("/auth/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest req) {
        return usuarios.login(req);
    }

    @PostMapping("/auth/registro")
    public LoginResponse registro(@Valid @RequestBody RegistroRequest req) {
        return usuarios.registrar(req);
    }

    @GetMapping("/me")
    public UsuarioDto yo() {
        return usuarios.dto(sesion.usuario());
    }

    @PutMapping("/me")
    public UsuarioDto actualizar(@Valid @RequestBody PerfilRequest req) {
        return usuarios.actualizarPerfil(sesion.usuario(), req);
    }

    @PutMapping("/me/token-fcm")
    public void tokenFcm(@Valid @RequestBody TokenFcmRequest req) {
        usuarios.guardarTokenFcm(sesion.usuario(), req.token());
    }
}
