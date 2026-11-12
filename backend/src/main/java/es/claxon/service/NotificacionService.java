package es.claxon.service;

import es.claxon.config.RelojClaxon;
import es.claxon.model.*;
import es.claxon.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Decide qué avisos hay que mandar y los envía (RF4, RF5, RF12).
 * Lo llama la tarea programada cada minuto y también el ayuntamiento al publicar.
 */
@Service
public class NotificacionService {

    private static final Logger log = LoggerFactory.getLogger(NotificacionService.class);
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("H:mm");
    /** Un retraso mayor que este provoca un aviso corregido (RF5). */
    static final int UMBRAL_CORRECCION_MIN = 5;

    private final JornadaRepository jornadas;
    private final SuscripcionRepository suscripciones;
    private final NotificacionRepository notificaciones;
    private final VinculoFamiliarRepository vinculos;
    private final EtaService eta;
    private final PushSender push;
    private final RelojClaxon reloj;

    public NotificacionService(JornadaRepository jornadas, SuscripcionRepository suscripciones,
                               NotificacionRepository notificaciones, VinculoFamiliarRepository vinculos,
                               EtaService eta, PushSender push, RelojClaxon reloj) {
        this.jornadas = jornadas;
        this.suscripciones = suscripciones;
        this.notificaciones = notificaciones;
        this.vinculos = vinculos;
        this.eta = eta;
        this.push = push;
        this.reloj = reloj;
    }

    /**
     * Revisa todas las rutas en marcha y manda los avisos que tocan ahora.
     * Es idempotente: se puede llamar tantas veces como se quiera sin repetir avisos.
     *
     * @return número de avisos enviados
     */
    @Transactional
    public synchronized int revisarLlegadas() {
        LocalDateTime ahora = reloj.ahora();
        int enviados = 0;
        for (Jornada j : jornadas.findByFechaAndEstado(ahora.toLocalDate(), EstadoJornada.EN_RUTA)) {
            Vendedor vendedor = j.getRuta().getVendedor();
            for (Parada p : j.getRuta().getParadas()) {
                if (p.getOrden() <= j.getParadaActual()) continue;          // ya ha pasado por ahí
                LocalDateTime llegada = eta.estimada(j, p);
                if (llegada == null || llegada.isBefore(ahora)) continue;
                for (Suscripcion s : suscripciones.findByPuebloAndTipo(p.getPueblo(), vendedor.getTipo())) {
                    enviados += avisarLlegada(s.getUsuario(), null, s.getMinAntes(), j, p, vendedor, llegada, ahora);
                    for (VinculoFamiliar v : vinculos.findByVecino(s.getUsuario())) {
                        enviados += avisarLlegada(v.getFamiliar(), s.getUsuario(), s.getMinAntes(), j, p, vendedor, llegada, ahora);
                    }
                }
            }
        }
        if (enviados > 0) log.info("Tarea de avisos: {} avisos enviados", enviados);
        return enviados;
    }

    private int avisarLlegada(Usuario destino, Usuario paraVecino, int minAntes, Jornada j, Parada p,
                              Vendedor vendedor, LocalDateTime llegada, LocalDateTime ahora) {
        List<Notificacion> previas = notificaciones.findByUsuarioAndJornadaAndParadaOrderByEnviadaEnAsc(destino, j, p);
        String lugar = p.getPueblo().getNombre() + " (" + p.getLugar() + ")";
        String quien = vendedor.getTipo().getQuien();
        String prefijo = paraVecino != null ? "Aviso para " + paraVecino.getNombre() + ": " : "";

        if (previas.isEmpty()) {
            // Primer aviso: cuando la llegada cae dentro de los próximos minAntes minutos.
            if (llegada.isAfter(ahora.plusMinutes(minAntes))) return 0;
            long faltan = Math.max(1, (Duration.between(ahora, llegada).toSeconds() + 59) / 60);   // redondeo hacia arriba
            String titulo = quien + " llega en " + faltan + " min";
            String texto = prefijo + vendedor.getNombreComercial() + " llega a " + lugar + " hacia las " + llegada.format(HH_MM) + ".";
            guardarYEnviar(destino, paraVecino, TipoNotificacion.LLEGADA, j, p, null, llegada, titulo, texto, ahora);
            return 1;
        }

        // Ya se avisó: solo se vuelve a avisar si se ha retrasado más de 5 minutos sobre lo último avisado.
        LocalDateTime ultimaAvisada = previas.get(previas.size() - 1).getEtaAvisada();
        if (ultimaAvisada != null && Duration.between(ultimaAvisada, llegada).toMinutes() > UMBRAL_CORRECCION_MIN) {
            String titulo = quien + " se retrasa";
            String texto = prefijo + vendedor.getNombreComercial() + " llegará a " + lugar + " hacia las " + llegada.format(HH_MM) + " (antes " + ultimaAvisada.format(HH_MM) + ").";
            guardarYEnviar(destino, paraVecino, TipoNotificacion.CORRECCION, j, p, null, llegada, titulo, texto, ahora);
            return 1;
        }
        return 0;
    }

    /** Envía al momento un aviso del ayuntamiento a los suscritos del pueblo (y a sus familiares). */
    @Transactional
    public int avisarPublicacion(Aviso aviso) {
        LocalDateTime ahora = reloj.ahora();
        List<Suscripcion> destino = new ArrayList<>(suscripciones.findByPuebloAndTipo(aviso.getPueblo(), TipoServicio.MEDICO));
        if (aviso.getTipo() == TipoAviso.CAMBIO) {
            // Un cambio general interesa a cualquiera que siga el pueblo.
            suscripciones.findByPueblo(aviso.getPueblo()).stream()
                    .filter(s -> destino.stream().noneMatch(d -> d.getUsuario().getId().equals(s.getUsuario().getId())))
                    .forEach(destino::add);
        }
        String titulo = switch (aviso.getTipo()) {
            case CONSULTA -> "Consulta médica en " + aviso.getPueblo().getNombre();
            case SIN_CONSULTA -> "Sin consulta médica en " + aviso.getPueblo().getNombre();
            case CAMBIO -> "Aviso del Ayuntamiento de " + aviso.getPueblo().getNombre();
        };
        String texto = AvisoService.describir(aviso, reloj.hoy());
        int n = 0;
        var yaAvisados = new java.util.HashSet<Long>();
        for (Suscripcion s : destino) {
            Usuario u = s.getUsuario();
            if (yaAvisados.add(u.getId())) {
                guardarYEnviar(u, null, TipoNotificacion.AYUNTAMIENTO, null, null, aviso, null, titulo, texto, ahora);
                n++;
            }
            for (VinculoFamiliar v : vinculos.findByVecino(u)) {
                if (yaAvisados.add(v.getFamiliar().getId())) {
                    guardarYEnviar(v.getFamiliar(), u, TipoNotificacion.AYUNTAMIENTO, null, null, aviso, null,
                            titulo, "Aviso para " + u.getNombre() + ": " + texto, ahora);
                    n++;
                }
            }
        }
        return n;
    }

    private void guardarYEnviar(Usuario destino, Usuario paraVecino, TipoNotificacion tipo, Jornada j, Parada p,
                                Aviso aviso, LocalDateTime llegada, String titulo, String texto, LocalDateTime ahora) {
        Notificacion n = new Notificacion();
        n.setUsuario(destino);
        n.setParaVecino(paraVecino);
        n.setTipo(tipo);
        n.setJornada(j);
        n.setParada(p);
        n.setAviso(aviso);
        n.setEtaAvisada(llegada);
        n.setTitulo(titulo);
        n.setTexto(texto);
        n.setEnviadaEn(ahora);
        notificaciones.save(n);
        push.enviar(destino, titulo, texto);
    }
}
