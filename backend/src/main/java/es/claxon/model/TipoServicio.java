package es.claxon.model;

/** Servicios a los que se puede suscribir un vecino. MEDICO no tiene vendedor: lo publica el ayuntamiento. */
public enum TipoServicio {
    PAN("Pan", "El panadero"),
    PESCADO("Pescado", "El pescadero"),
    FRUTA("Fruta", "El frutero"),
    CARNE("Carne", "El carnicero"),
    VARIOS("Varios", "El vendedor"),
    MEDICO("Médico", "El médico");

    private final String etiqueta;
    private final String quien;

    TipoServicio(String etiqueta, String quien) {
        this.etiqueta = etiqueta;
        this.quien = quien;
    }

    public String getEtiqueta() { return etiqueta; }

    /** "El panadero", usado para redactar la notificación. */
    public String getQuien() { return quien; }
}
