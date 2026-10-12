/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : plantilla_programa_concurrente.sql                           ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Procedimiento de ejemplo para registrar en EBS.              ║
║ Parámetros     :                                                              ║
║   errbuf: OUT VARCHAR2, mensaje al gestor                                     ║
║   retcode: OUT VARCHAR2, 0 normal / 1 advertencia / 2 error                   ║
║   p_texto: IN VARCHAR2, único parámetro funcional                             ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- DDL: crea o reemplaza este objeto y produce confirmaciones implícitas.
-- Revisar nombre y desplegar según las normas de personalización de la instancia.
-- Se ejecuta desde el gestor concurrente; no inicializar otra responsabilidad aquí.
CREATE OR REPLACE PROCEDURE xx_ejemplo_concurrente (
  errbuf OUT VARCHAR2,
  retcode OUT VARCHAR2,
  p_texto IN VARCHAR2
) IS
BEGIN
  errbuf := NULL;
  retcode := '0';
  fnd_file.put_line(fnd_file.log, 'Inicio del programa de ejemplo.');
  IF p_texto IS NULL THEN
    retcode := '1';
    errbuf := 'No se recibió texto para procesar.';
    fnd_file.put_line(fnd_file.log, errbuf);
    RETURN;
  END IF;
  -- Sustituir por la lógica funcional; el ejemplo no modifica datos.
  fnd_file.put_line(fnd_file.output, 'Texto recibido: ' || SUBSTR(p_texto, 1, 240));
  fnd_file.put_line(fnd_file.log, 'Fin del programa de ejemplo.');
EXCEPTION
  WHEN OTHERS THEN
    retcode := '2';
    errbuf := SUBSTR('Error durante el procesamiento: ' || SQLERRM, 1, 240);
    BEGIN
      fnd_file.put_line(fnd_file.log, errbuf);
      fnd_file.put_line(fnd_file.log, dbms_utility.format_error_backtrace);
    EXCEPTION
      WHEN OTHERS THEN
        -- Preservar RETCODE y ERRBUF aunque también falle la escritura del log.
        NULL;
    END;
END xx_ejemplo_concurrente;
/
SHOW ERRORS PROCEDURE xx_ejemplo_concurrente
