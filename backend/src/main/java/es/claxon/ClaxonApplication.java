package es.claxon;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.TimeZone;

@SpringBootApplication
@EnableScheduling
public class ClaxonApplication {

    public static void main(String[] args) {
        // Todas las horas de la app son horas de Teruel.
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Madrid"));
        SpringApplication.run(ClaxonApplication.class, args);
    }
}
