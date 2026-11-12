package es.claxon.service;

import es.claxon.model.Usuario;

/** Envía una notificación al móvil. Hay dos implementaciones: Firebase (real) y registro en log. */
public interface PushSender {
    void enviar(Usuario destinatario, String titulo, String texto);
}
