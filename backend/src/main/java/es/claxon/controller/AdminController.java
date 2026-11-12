package es.claxon.controller;

import es.claxon.dto.Dtos.*;
import es.claxon.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UsuarioService usuarios;

    public AdminController(UsuarioService usuarios) {
        this.usuarios = usuarios;
    }

    @GetMapping("/usuarios")
    public List<UsuarioDto> usuarios() {
        return usuarios.todos();
    }

    @PostMapping("/usuarios")
    @ResponseStatus(HttpStatus.CREATED)
    public UsuarioDto crear(@Valid @RequestBody NuevoUsuarioRequest req) {
        return usuarios.crearPorAdmin(req);
    }

}
