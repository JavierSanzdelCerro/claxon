package es.claxon;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import es.claxon.config.RelojClaxon;
import es.claxon.service.NotificacionService;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Prueba de punta a punta con los datos de demostración (piloto en Cuencas Mineras):
 * HU1 aviso 15 min antes, HU2 iniciar ruta, HU3 encargos por parada, HU4 encargo,
 * HU5 aviso del ayuntamiento, HU6 familiar, HU7 tablón, HU9 vio el aviso.
 * La hora se fija a mano para que el test no dependa del reloj real.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class FlujoCompletoTest {

    static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    /** Jueves: pasan el pan y el pescado. */
    static final LocalDate JUEVES = LocalDate.of(2026, 11, 12);

    @TestConfiguration
    static class RelojFijo {
        @Bean
        @Primary
        RelojClaxon relojFijo() {
            return new RelojClaxon(Clock.fixed(LocalDateTime.of(JUEVES, LocalTime.of(9, 55)).atZone(MADRID).toInstant(), MADRID));
        }
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired RelojClaxon reloj;
    @Autowired NotificacionService notificaciones;

    static String tPan, tCarmen, tLucia, tAntonio, tAyto;
    static long rutaPan, carmenId;

    void hora(int h, int m) {
        reloj.usarReloj(Clock.fixed(LocalDateTime.of(JUEVES, LocalTime.of(h, m)).atZone(MADRID).toInstant(), MADRID));
    }

    String login(String user) throws Exception {
        return llamar(post("/api/auth/login").content("{\"username\":\"" + user + "\",\"password\":\"claxon123\"}"), null, 200)
                .get("token").asText();
    }

    JsonNode llamar(MockHttpServletRequestBuilder req, String token, int esperado) throws Exception {
        req.contentType(MediaType.APPLICATION_JSON);
        if (token != null) req.header("Authorization", "Bearer " + token);
        var res = mvc.perform(req).andReturn().getResponse();
        res.setCharacterEncoding("UTF-8");
        assertEquals(esperado, res.getStatus(), res.getContentAsString());
        String body = res.getContentAsString();
        return body.isEmpty() ? null : json.readTree(body);
    }

    JsonNode avisos(String token) throws Exception {
        return llamar(get("/api/notificaciones"), token, 200);
    }

    @Test @Order(1)
    void seCarganLos236PueblosYLosUsuariosDemo() throws Exception {
        hora(9, 55);
        assertEquals(236, llamar(get("/api/pueblos"), null, 200).size());
        assertEquals("La Hoz de la Vieja", llamar(get("/api/pueblos?q=hoz de la"), null, 200).get(0).get("nombre").asText());
        tPan = login("pan.martin");
        tCarmen = login("carmen");
        tLucia = login("lucia");
        tAntonio = login("antonio");
        tAyto = login("ayto.fuenferrada");
        carmenId = llamar(get("/api/me"), tCarmen, 200).get("id").asLong();
        llamar(post("/api/auth/login").content("{\"username\":\"carmen\",\"password\":\"mala\"}"), null, 401);
    }

    @Test @Order(2)
    void seguridadPorRoles() throws Exception {
        llamar(get("/api/me"), null, 401);
        llamar(get("/api/vendedor/hoy"), tCarmen, 403);
        llamar(get("/api/ayuntamiento/panel"), tPan, 403);
        llamar(get("/api/familia/vecinos"), tCarmen, 403);
        // Un vecino no puede ver los encargos de otro.
        llamar(get("/api/encargos?vecinoId=" + carmenId), tAntonio, 403);
        // No se puede registrar uno mismo como vendedor.
        llamar(post("/api/auth/registro").content("""
                {"username":"falso","password":"123456","nombre":"X","rol":"VENDEDOR"}"""), null, 400);
    }

    @Test @Order(3)
    void hoyMuestraElHorarioHabitualAntesDeSalir() throws Exception {
        long fuenferrada = llamar(get("/api/me"), tCarmen, 200).get("pueblo").get("id").asLong();
        JsonNode hoy = llamar(get("/api/pueblos/" + fuenferrada + "/hoy"), null, 200);
        assertEquals(2, hoy.get("pasos").size());
        assertEquals("10:40", hoy.get("pasos").get(0).get("hora").asText());   // pan
        assertEquals("12:15", hoy.get("pasos").get(1).get("hora").asText());   // pescado
        assertEquals("PREVISTA", hoy.get("pasos").get(0).get("estado").asText());
        assertEquals("CONSULTA", hoy.get("medico").get("estado").asText());    // jueves 9–11
        // El tablón del bar es público y da lo mismo.
        assertEquals(2, llamar(get("/api/public/tablon/" + fuenferrada), null, 200).get("pasos").size());
    }

    @Test @Order(4)
    void elVecinoHaceUnEncargoYElVendedorLoVePorParada() throws Exception {
        long fuenferrada = llamar(get("/api/me"), tCarmen, 200).get("pueblo").get("id").asLong();
        JsonNode paradas = llamar(get("/api/pueblos/" + fuenferrada + "/paradas"), null, 200);
        long paradaPan = 0;
        for (JsonNode p : paradas) if (p.get("tipo").asText().equals("PAN")) paradaPan = p.get("paradaId").asLong();
        JsonNode e = llamar(post("/api/encargos").content("""
                {"paradaId":%d,"fecha":"2026-11-12","texto":"1 bizcocho","idCliente":"abc-1"}""".formatted(paradaPan)), tCarmen, 201);
        // Reenviar el mismo encargo (cola sin conexión) no lo duplica.
        JsonNode otra = llamar(post("/api/encargos").content("""
                {"paradaId":%d,"fecha":"2026-11-12","texto":"1 bizcocho","idCliente":"abc-1"}""".formatted(paradaPan)), tCarmen, 201);
        assertEquals(e.get("id").asLong(), otra.get("id").asLong());
        // El domingo no pasa.
        llamar(post("/api/encargos").content("""
                {"paradaId":%d,"fecha":"2026-11-15","texto":"pan"}""".formatted(paradaPan)), tCarmen, 400);
        // La hija lo hace por ella (modo familiar).
        llamar(post("/api/encargos").content("""
                {"paradaId":%d,"fecha":"2026-11-12","texto":"1 barra más","vecinoId":%d}""".formatted(paradaPan, carmenId)), tLucia, 201);
        // Antonio no puede cancelar el de Carmen.
        llamar(post("/api/encargos/" + e.get("id").asLong() + "/cancelar"), tAntonio, 403);

        rutaPan = llamar(get("/api/vendedor/hoy"), tPan, 200).get(0).get("rutaId").asLong();
        JsonNode porParada = llamar(get("/api/vendedor/rutas/" + rutaPan + "/encargos"), tPan, 200);
        assertEquals("Fuenferrada", porParada.get(1).get("pueblo").asText());
        assertEquals(3, porParada.get(1).get("encargos").size());   // demo + bizcocho + el de la hija
        assertEquals(1, porParada.get(2).get("encargos").size());   // Antonio en Segura
    }

    @Test @Order(5)
    void avisoQuinceMinutosAntesUnaSolaVez() throws Exception {
        hora(9, 55);
        JsonNode r = llamar(post("/api/vendedor/rutas/" + rutaPan + "/iniciar"), tPan, 200);
        assertEquals("EN_RUTA", r.get("estadoJornada").asText());
        assertEquals("10:35", r.get("paradas").get(1).get("hora").asText());   // 9:55 + 40

        hora(10, 19);
        notificaciones.revisarLlegadas();
        assertEquals(0, avisos(tCarmen).size(), "a las 10:19 faltan 16 minutos: aún no");

        hora(10, 20);
        notificaciones.revisarLlegadas();
        JsonNode a = avisos(tCarmen);
        assertEquals(1, a.size());
        assertEquals("El panadero llega en 15 min", a.get(0).get("titulo").asText());
        assertTrue(a.get(0).get("texto").asText().contains("Fuenferrada"));
        // La hija también lo recibe.
        assertEquals("Carmen", avisos(tLucia).get(0).get("paraVecino").asText());

        hora(10, 21);
        notificaciones.revisarLlegadas();
        notificaciones.revisarLlegadas();
        assertEquals(1, avisos(tCarmen).size(), "nunca dos avisos por la misma llegada");
    }

    @Test @Order(6)
    void heLlegadoTardeProvocaAvisoCorregido() throws Exception {
        // Llega a Martín del Río (previsto 9:55) a las 10:22: 27 min de retraso → Fuenferrada pasa a las 11:02.
        hora(10, 22);
        JsonNode r = llamar(post("/api/vendedor/rutas/" + rutaPan + "/llegado"), tPan, 200);
        assertEquals(27, r.get("retrasoMin").asInt());
        assertEquals("11:02", r.get("paradas").get(1).get("hora").asText());
        JsonNode a = avisos(tCarmen);
        assertEquals(2, a.size());
        assertEquals("CORRECCION", a.get(0).get("tipo").asText());
        assertTrue(a.get(0).get("texto").asText().contains("11:02"));

        // Retraso pequeño (≤ 5 min) no genera otro aviso.
        hora(10, 50);
        notificaciones.revisarLlegadas();
        assertEquals(2, avisos(tCarmen).size());

        // Antonio (Segura, 11:42 ahora) recibe su aviso cuando toca.
        hora(11, 27);
        notificaciones.revisarLlegadas();
        assertEquals(1, avisos(tAntonio).size());
    }

    @Test @Order(7)
    void vecinoVeElAvisoYLaFamiliaLoSabe() throws Exception {
        long id = avisos(tCarmen).get(0).get("id").asLong();
        llamar(post("/api/notificaciones/" + id + "/vista"), tCarmen, 200);
        JsonNode vecinos = llamar(get("/api/familia/vecinos"), tLucia, 200);
        assertEquals("Carmen", vecinos.get(0).get("nombre").asText());
        assertFalse(vecinos.get(0).get("ultimoAviso").get("vistaEn").isNull());
        // Lucía no puede marcar como visto un aviso de Carmen.
        llamar(post("/api/notificaciones/" + id + "/vista"), tLucia, 403);
    }

    @Test @Order(8)
    void ayuntamientoPublicaSinConsultaYLlegaAlMomento() throws Exception {
        hora(11, 30);
        JsonNode p = llamar(post("/api/ayuntamiento/avisos").content("""
                {"tipo":"SIN_CONSULTA","fecha":"2026-11-12","texto":"Hoy no hay consulta. Centro de salud de Utrillas."}"""), tAyto, 201);
        assertEquals(2, p.get("avisados").asInt());   // Carmen (suscrita a médico) y su hija
        JsonNode a = avisos(tCarmen);
        assertEquals("AYUNTAMIENTO", a.get(0).get("tipo").asText());
        JsonNode panel = llamar(get("/api/ayuntamiento/panel"), tAyto, 200);
        assertEquals("SIN_CONSULTA", panel.get("hoy").get("medico").get("estado").asText());
        assertEquals(1, panel.get("vecinosSuscritos").asInt());
    }

    @Test @Order(9)
    void vendedorEntregaEncargosYVeEstadisticas() throws Exception {
        JsonNode porParada = llamar(get("/api/vendedor/rutas/" + rutaPan + "/encargos"), tPan, 200);
        long encargo = porParada.get(1).get("encargos").get(0).get("id").asLong();
        assertEquals("ENTREGADO", llamar(post("/api/vendedor/encargos/" + encargo + "/entregado"), tPan, 200).get("estado").asText());
        JsonNode semanas = llamar(get("/api/vendedor/estadisticas"), tPan, 200);
        assertEquals(8, semanas.size());
        assertEquals(4, semanas.get(7).get("encargos").asInt());
        assertEquals(1, semanas.get(7).get("entregados").asInt());
    }

    @Test @Order(10)
    void elVendedorEditaSuRuta() throws Exception {
        JsonNode rutas = llamar(get("/api/vendedor/rutas"), tPan, 200);
        JsonNode ruta = rutas.get(0);
        // Quitar una parada con encargos no se permite.
        var paradas = ruta.get("paradas");
        String sinFuenferrada = """
                {"nombre":"Ruta de la mañana","diasSemana":"1,2,3,4,5,6","horaSalidaHabitual":"09:30","paradas":[
                  {"id":%d,"puebloId":%d,"lugar":"Plaza","minDesdeSalida":0}]}""".formatted(
                paradas.get(0).get("id").asLong(), paradas.get(0).get("pueblo").get("id").asLong());
        llamar(put("/api/vendedor/rutas/" + ruta.get("id").asLong()).content(sinFuenferrada), tPan, 400);
        // Crear una ruta nueva sí.
        JsonNode nueva = llamar(post("/api/vendedor/rutas").content("""
                {"nombre":"Tarde","diasSemana":"5","horaSalidaHabitual":"17:00","paradas":[
                  {"puebloId":%d,"lugar":"Plaza","minDesdeSalida":0},
                  {"puebloId":%d,"lugar":"Fuente","minDesdeSalida":25}]}""".formatted(
                paradas.get(0).get("pueblo").get("id").asLong(), paradas.get(1).get("pueblo").get("id").asLong())), tPan, 201);
        assertEquals(2, nueva.get("paradas").size());
        // Los minutos no pueden ir hacia atrás.
        llamar(post("/api/vendedor/rutas").content("""
                {"nombre":"Mal","diasSemana":"5","paradas":[
                  {"puebloId":1,"lugar":"A","minDesdeSalida":30},{"puebloId":2,"lugar":"B","minDesdeSalida":10}]}"""), tPan, 400);
    }

    @Test @Order(11)
    void familiarSeVinculaConElCodigo() throws Exception {
        JsonNode reg = llamar(post("/api/auth/registro").content("""
                {"username":"pedro","password":"secreto1","nombre":"Pedro","rol":"FAMILIAR"}"""), null, 200);
        String tPedro = reg.get("token").asText();
        llamar(post("/api/familia/vincular").content("{\"codigo\":\"000000\"}"), tPedro, 400);
        JsonNode v = llamar(post("/api/familia/vincular").content("{\"codigo\":\"246810\"}"), tPedro, 200);
        assertEquals("Carmen", v.get("nombre").asText());
        // Ya puede gestionar sus suscripciones.
        assertEquals(3, llamar(get("/api/suscripciones?vecinoId=" + carmenId), tPedro, 200).size());
        assertEquals("Fuenferrada", llamar(get("/api/familia/vecinos/" + carmenId + "/hoy"), tPedro, 200)
                .get("pueblo").get("nombre").asText());
    }
}
