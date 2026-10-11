/*
 * Archivo: EjemploBasico.java
 * Autor: Freddy E. Aparicio M.
 * Fecha: 10/10/2026
 * Versión: 1.0
 * Descripción: Clase de consola invocada desde XX_EJEMPLO_HOST.prog.
 * Historial: 10/10/2026 — versión 1.0, creación.
 */
public class EjemploBasico {
    public static void main(String[] args) {
        if (args.length != 1 || !args[0].matches("LOCAL|[0-9]+")) {
            System.err.println("Error: indica LOCAL o un ID de solicitud numérico.");
            System.exit(1);
        }
        System.out.println("Ejecución Java correcta. Solicitud: " + args[0]);
    }
}
