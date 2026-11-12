package es.claxon.model;

public enum TipoNotificacion {
    /** Primer aviso: «llega en 15 minutos». */
    LLEGADA,
    /** La llegada se ha retrasado más de 5 minutos respecto a lo avisado. */
    CORRECCION,
    /** Aviso publicado por el ayuntamiento. */
    AYUNTAMIENTO
}
