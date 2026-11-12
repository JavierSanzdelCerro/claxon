package es.claxon.model;

/** Lo que publica el ayuntamiento. */
public enum TipoAviso {
    /** Día de consulta médica (fecha + horario). */
    CONSULTA,
    /** Se suspende la consulta de ese día. */
    SIN_CONSULTA,
    /** Cualquier otro cambio o aviso de última hora. */
    CAMBIO
}
