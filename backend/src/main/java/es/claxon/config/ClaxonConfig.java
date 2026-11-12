package es.claxon.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.time.ZoneId;

@Configuration
public class ClaxonConfig {

    @Bean
    public RelojClaxon relojClaxon(@Value("${claxon.zona-horaria:Europe/Madrid}") String zona) {
        return new RelojClaxon(Clock.system(ZoneId.of(zona)));
    }
}
