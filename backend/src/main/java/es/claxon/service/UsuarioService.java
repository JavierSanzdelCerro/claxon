package es.claxon.service;

import es.claxon.config.ApiException;
import es.claxon.dto.Dtos.*;
import es.claxon.model.*;
import es.claxon.repository.PuebloRepository;
import es.claxon.repository.UsuarioRepository;
import es.claxon.repository.VendedorRepository;
import es.claxon.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;

@Service
public class UsuarioService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UsuarioRepository usuarios;
    private final PuebloRepository pueblos;
    private final VendedorRepository vendedores;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public UsuarioService(UsuarioRepository usuarios, PuebloRepository pueblos, VendedorRepository vendedores,
                          PasswordEncoder encoder, JwtService jwt) {
        this.usuarios = usuarios;
        this.pueblos = pueblos;
        this.vendedores = vendedores;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest req) {
        Usuario u = usuarios.findByUsername(req.username().trim().toLowerCase())
                .filter(x -> encoder.matches(req.password(), x.getPasswordHash()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Usuario o contraseña incorrectos"));
        return new LoginResponse(jwt.generar(u), dto(u));
    }

    /** Registro abierto solo para vecinos y familiares. Vendedores y ayuntamientos los da de alta el administrador. */
    @Transactional
    public LoginResponse registrar(RegistroRequest req) {
        if (req.rol() != Rol.VECINO && req.rol() != Rol.FAMILIAR) {
            throw ApiException.invalido("Solo pueden registrarse vecinos y familiares");
        }
        if (req.rol() == Rol.VECINO && req.puebloId() == null) {
            throw ApiException.invalido("Elige tu pueblo");
        }
        Usuario u = crear(req.username(), req.password(), req.nombre(), req.telefono(), req.rol(), req.puebloId());
        return new LoginResponse(jwt.generar(u), dto(u));
    }

    @Transactional
    public Usuario crear(String username, String password, String nombre, String telefono, Rol rol, Long puebloId) {
        String user = username.trim().toLowerCase();
        if (usuarios.existsByUsername(user)) throw new ApiException(HttpStatus.CONFLICT, "Ese nombre de usuario ya existe");
        Usuario u = new Usuario();
        u.setUsername(user);
        u.setPasswordHash(encoder.encode(password));
        u.setNombre(nombre.trim());
        u.setTelefono(telefono);
        u.setRol(rol);
        if (puebloId != null) u.setPueblo(pueblos.findById(puebloId).orElseThrow(() -> ApiException.noEncontrado("Pueblo")));
        if (rol == Rol.VECINO) u.setCodigoVinculo(codigoLibre());
        return usuarios.save(u);
    }

    @Transactional
    public UsuarioDto crearPorAdmin(NuevoUsuarioRequest req) {
        if (req.rol() == Rol.AYUNTAMIENTO && req.puebloId() == null) throw ApiException.invalido("Indica el pueblo del ayuntamiento");
        if (req.rol() == Rol.VENDEDOR && (req.nombreComercial() == null || req.tipo() == null || req.tipo() == TipoServicio.MEDICO)) {
            throw ApiException.invalido("Indica el nombre comercial y el tipo de venta");
        }
        Usuario u = crear(req.username(), req.password(), req.nombre(), req.telefono(), req.rol(), req.puebloId());
        if (req.rol() == Rol.VENDEDOR) {
            Vendedor v = new Vendedor();
            v.setUsuario(u);
            v.setNombreComercial(req.nombreComercial());
            v.setTipo(req.tipo());
            vendedores.save(v);
        }
        return dto(u);
    }

    @Transactional
    public UsuarioDto actualizarPerfil(Usuario u, PerfilRequest req) {
        if (req.nombre() != null && !req.nombre().isBlank()) u.setNombre(req.nombre().trim());
        if (req.telefono() != null) u.setTelefono(req.telefono().isBlank() ? null : req.telefono().trim());
        if (req.textoGrande() != null) u.setTextoGrande(req.textoGrande());
        if (req.puebloId() != null && u.getRol() != Rol.AYUNTAMIENTO) {
            u.setPueblo(pueblos.findById(req.puebloId()).orElseThrow(() -> ApiException.noEncontrado("Pueblo")));
        }
        return dto(usuarios.save(u));
    }

    @Transactional
    public void guardarTokenFcm(Usuario u, String token) {
        u.setTokenFcm(token);
        usuarios.save(u);
    }

    @Transactional(readOnly = true)
    public List<UsuarioDto> todos() {
        return usuarios.findAll().stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public UsuarioDto dto(Usuario u) {
        Vendedor v = u.getRol() == Rol.VENDEDOR ? vendedores.findByUsuario(u).orElse(null) : null;
        return UsuarioDto.de(u, v);
    }

    private String codigoLibre() {
        String c;
        do {
            c = String.format("%06d", RANDOM.nextInt(1_000_000));
        } while (usuarios.findByCodigoVinculo(c).isPresent());
        return c;
    }
}
