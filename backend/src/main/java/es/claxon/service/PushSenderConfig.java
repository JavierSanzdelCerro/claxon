package es.claxon.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;

/**
 * Si existe el fichero de credenciales de Firebase (claxon.fcm.credenciales) se usa FCM;
 * si no, los avisos se registran en el log y la app los recoge igualmente de /api/notificaciones.
 */
@Configuration
public class PushSenderConfig {

    private static final Logger log = LoggerFactory.getLogger(PushSenderConfig.class);

    @Bean
    public PushSender pushSender(@Value("${claxon.fcm.credenciales:}") String rutaCredenciales) {
        if (rutaCredenciales == null || rutaCredenciales.isBlank()) {
            log.info("FCM no configurado: los avisos se guardan y la app los consulta por la API");
            return (u, titulo, texto) -> log.info("AVISO → {} ({}): {} · {}", u.getNombre(), u.getUsername(), titulo, texto);
        }
        try (FileInputStream in = new FileInputStream(rutaCredenciales)) {
            FirebaseOptions opciones = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in)).build();
            FirebaseApp app = FirebaseApp.getApps().isEmpty() ? FirebaseApp.initializeApp(opciones) : FirebaseApp.getInstance();
            FirebaseMessaging fcm = FirebaseMessaging.getInstance(app);
            log.info("FCM activado");
            return (u, titulo, texto) -> {
                if (u.getTokenFcm() == null || u.getTokenFcm().isBlank()) return;
                Message m = Message.builder()
                        .setToken(u.getTokenFcm())
                        .setNotification(Notification.builder().setTitle(titulo).setBody(texto).build())
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder().setChannelId("avisos").build())
                                .build())
                        .build();
                try {
                    fcm.send(m);
                } catch (Exception e) {
                    log.warn("No se pudo enviar el push a {}: {}", u.getUsername(), e.getMessage());
                }
            };
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo iniciar Firebase con " + rutaCredenciales, e);
        }
    }
}
