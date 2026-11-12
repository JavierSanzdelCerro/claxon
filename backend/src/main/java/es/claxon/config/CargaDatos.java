package es.claxon.config;

import es.claxon.model.*;
import es.claxon.repository.*;
import es.claxon.service.UsuarioService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;

/**
 * Al arrancar:
 * 1) carga los 236 municipios de Teruel (código INE y comarca, datos abiertos) si la tabla está vacía;
 * 2) crea el administrador si no existe;
 * 3) en modo demo, crea un piloto en Cuencas Mineras con datos de ejemplo.
 */
@Component
public class CargaDatos implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(CargaDatos.class);
    public static final String CLAVE_DEMO = "claxon123";

    private final PuebloRepository pueblos;
    private final UsuarioRepository usuarios;
    private final UsuarioService usuarioService;
    private final VendedorRepository vendedores;
    private final RutaRepository rutas;
    private final SuscripcionRepository suscripciones;
    private final VinculoFamiliarRepository vinculos;
    private final EncargoRepository encargos;
    private final AvisoRepository avisos;
    private final RelojClaxon reloj;
    private final boolean demo;
    private final String adminPassword;

    public CargaDatos(PuebloRepository pueblos, UsuarioRepository usuarios, UsuarioService usuarioService,
                      VendedorRepository vendedores, RutaRepository rutas, SuscripcionRepository suscripciones,
                      VinculoFamiliarRepository vinculos, EncargoRepository encargos, AvisoRepository avisos,
                      RelojClaxon reloj,
                      @Value("${claxon.demo:false}") boolean demo,
                      @Value("${claxon.admin.password:claxon123}") String adminPassword) {
        this.pueblos = pueblos;
        this.usuarios = usuarios;
        this.usuarioService = usuarioService;
        this.vendedores = vendedores;
        this.rutas = rutas;
        this.suscripciones = suscripciones;
        this.vinculos = vinculos;
        this.encargos = encargos;
        this.avisos = avisos;
        this.reloj = reloj;
        this.demo = demo;
        this.adminPassword = adminPassword;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) throws Exception {
        if (pueblos.count() == 0) cargarPueblos();
        if (!usuarios.existsByUsername("admin")) {
            usuarioService.crear("admin", adminPassword, "Administración CLAXON", null, Rol.ADMIN, null);
        }
        if (demo && !usuarios.existsByUsername("carmen")) cargarDemo();
    }

    private void cargarPueblos() throws Exception {
        List<Pueblo> lista = new ArrayList<>();
        try (var in = new BufferedReader(new InputStreamReader(
                new ClassPathResource("data/pueblos_teruel.csv").getInputStream(), StandardCharsets.UTF_8))) {
            in.readLine(); // cabecera
            String linea;
            while ((linea = in.readLine()) != null) {
                List<String> c = csv(linea);
                lista.add(new Pueblo(nombreNatural(c.get(1)), c.get(0), c.get(2), Integer.valueOf(c.get(3))));
            }
        }
        pueblos.saveAll(lista);
        log.info("Cargados {} municipios de Teruel", lista.size());
    }

    /** El INE escribe «Hoz de la Vieja, La»; en pantalla queda mejor «La Hoz de la Vieja». */
    static String nombreNatural(String ine) {
        int coma = ine.lastIndexOf(", ");
        if (coma > 0) {
            String articulo = ine.substring(coma + 2);
            if (articulo.matches("(?i)(la|el|los|las)")) return articulo + " " + ine.substring(0, coma);
        }
        return ine;
    }

    /** Separa una línea CSV respetando las comillas. */
    static List<String> csv(String linea) {
        List<String> campos = new ArrayList<>();
        StringBuilder actual = new StringBuilder();
        boolean comillas = false;
        for (char ch : linea.toCharArray()) {
            if (ch == '"') comillas = !comillas;
            else if (ch == ',' && !comillas) { campos.add(actual.toString()); actual.setLength(0); }
            else actual.append(ch);
        }
        campos.add(actual.toString());
        return campos;
    }

    // ---------------------------------------------------------------- demo

    private void cargarDemo() {
        Pueblo martin = pueblo("44144");     // Martín del Río
        Pueblo fuenferrada = pueblo("44110");
        Pueblo segura = pueblo("44211");     // Segura de los Baños
        Pueblo hoz = pueblo("44124");        // La Hoz de la Vieja
        Pueblo utrillas = pueblo("44238");

        Usuario carmen = usuarioService.crear("carmen", CLAVE_DEMO, "Carmen", "600111222", Rol.VECINO, fuenferrada.getId());
        carmen.setCodigoVinculo("246810");
        Usuario antonio = usuarioService.crear("antonio", CLAVE_DEMO, "Antonio", "600333444", Rol.VECINO, segura.getId());
        Usuario lucia = usuarioService.crear("lucia", CLAVE_DEMO, "Lucía (hija de Carmen)", "600555666", Rol.FAMILIAR, null);
        lucia.setTextoGrande(false);
        usuarioService.crear("ayto.fuenferrada", CLAVE_DEMO, "Ayuntamiento de Fuenferrada", "978000000", Rol.AYUNTAMIENTO, fuenferrada.getId());

        VinculoFamiliar v = new VinculoFamiliar();
        v.setFamiliar(lucia);
        v.setVecino(carmen);
        vinculos.save(v);

        // Panadería: todos los días menos el domingo, sale a las 10:00.
        Vendedor pan = vendedor("pan.martin", "Juan (panadero)", "Panadería Martín", TipoServicio.PAN);
        Ruta rutaPan = ruta(pan, "Ruta de la mañana", "1,2,3,4,5,6", LocalTime.of(10, 0),
                parada(martin, "Plaza", 0), parada(fuenferrada, "Plaza", 40),
                parada(segura, "Plaza", 80), parada(hoz, "Junto a la iglesia", 120));

        // Pescadería: martes, jueves y sábado, sale de Utrillas a las 11:00.
        Vendedor pescado = vendedor("pescados.lola", "Lola (pescadera)", "Pescados Lola", TipoServicio.PESCADO);
        ruta(pescado, "Cuencas Mineras", "2,4,6", LocalTime.of(11, 0),
                parada(utrillas, "Mercado", 0), parada(fuenferrada, "Plaza", 75), parada(segura, "Plaza", 105));

        suscribir(carmen, fuenferrada, TipoServicio.PAN);
        suscribir(carmen, fuenferrada, TipoServicio.PESCADO);
        suscribir(carmen, fuenferrada, TipoServicio.MEDICO);
        suscribir(antonio, segura, TipoServicio.PAN);

        // Encargos para el próximo día de ruta.
        LocalDate hoy = reloj.hoy();
        LocalDate diaPan = hoy;
        while (!rutaPan.seHaceEl(diaPan.getDayOfWeek())) diaPan = diaPan.plusDays(1);
        encargo(carmen, rutaPan.getParadas().get(1), diaPan, "2 barras y 1 hogaza");
        encargo(antonio, rutaPan.getParadas().get(2), diaPan, "6 magdalenas y 1 barra");

        // Consulta médica: lunes y jueves de 9:00 a 11:00, esta semana y la siguiente.
        LocalDate lunes = hoy.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        Usuario ayto = usuarios.findByUsername("ayto.fuenferrada").orElseThrow();
        for (int semana = 0; semana < 2; semana++) {
            for (int dia : new int[]{0, 3}) {
                Aviso a = new Aviso();
                a.setPueblo(fuenferrada);
                a.setAutor(ayto);
                a.setTipo(TipoAviso.CONSULTA);
                a.setFecha(lunes.plusWeeks(semana).plusDays(dia));
                a.setHoraInicio(LocalTime.of(9, 0));
                a.setHoraFin(LocalTime.of(11, 0));
                a.setCreadoEn(reloj.ahora().minusDays(7));
                avisos.save(a);
            }
        }
        log.info("Datos de demostración creados. Usuarios: carmen, antonio, lucia, pan.martin, pescados.lola, "
                + "ayto.fuenferrada, admin (contraseña {})", CLAVE_DEMO);
    }

    private Pueblo pueblo(String ine) {
        return pueblos.findByCodIne(ine).orElseThrow();
    }

    private Vendedor vendedor(String username, String nombre, String comercial, TipoServicio tipo) {
        Usuario u = usuarioService.crear(username, CLAVE_DEMO, nombre, "600777888", Rol.VENDEDOR, null);
        Vendedor v = new Vendedor();
        v.setUsuario(u);
        v.setNombreComercial(comercial);
        v.setTipo(tipo);
        return vendedores.save(v);
    }

    private Ruta ruta(Vendedor v, String nombre, String dias, LocalTime salida, Parada... paradas) {
        Ruta r = new Ruta();
        r.setVendedor(v);
        r.setNombre(nombre);
        r.setDiasSemana(dias);
        r.setHoraSalidaHabitual(salida);
        int orden = 1;
        for (Parada p : paradas) {
            p.setRuta(r);
            p.setOrden(orden++);
            r.getParadas().add(p);
        }
        return rutas.save(r);
    }

    private Parada parada(Pueblo pueblo, String lugar, int min) {
        Parada p = new Parada();
        p.setPueblo(pueblo);
        p.setLugar(lugar);
        p.setMinDesdeSalida(min);
        return p;
    }

    private void suscribir(Usuario u, Pueblo p, TipoServicio tipo) {
        Suscripcion s = new Suscripcion();
        s.setUsuario(u);
        s.setPueblo(p);
        s.setTipo(tipo);
        suscripciones.save(s);
    }

    private void encargo(Usuario u, Parada p, LocalDate fecha, String texto) {
        Encargo e = new Encargo();
        e.setUsuario(u);
        e.setParada(p);
        e.setFecha(fecha);
        e.setTexto(texto);
        encargos.save(e);
    }
}
