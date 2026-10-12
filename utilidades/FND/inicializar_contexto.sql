/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : inicializar_contexto.sql                                     ║
║ Autor          : Freddy E. Aparicio M.                                        ║
║ Fecha creación : 12/10/2026                                                   ║
║ Versión        : 1.0                                                          ║
║ Descripción    : Contexto EBS para una sesión externa.                        ║
║ Parámetros     :                                                              ║
║   p_user_id: NUMBER, obligatorio                                              ║
║   p_resp_id: NUMBER, obligatorio                                              ║
║   p_resp_appl_id: NUMBER, obligatorio                                         ║
║ Notas          : Oracle EBS R12.1/R12.2. Revisar README antes de ejecutar.    ║
║                  Pendiente validación nativa en Oracle EBS.                   ║
║ Actualizaciones: 12/10/2026 — versión 1.0, creación.                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
BEGIN
  IF :p_user_id IS NULL OR :p_user_id < 0
     OR :p_resp_id IS NULL OR :p_resp_id < 0
     OR :p_resp_appl_id IS NULL OR :p_resp_appl_id < 0 THEN
    raise_application_error(-20001, 'Indique usuario, responsabilidad y aplicación válidos.');
  END IF;
  -- Los identificadores deben corresponder a una responsabilidad autorizada.
  -- APPS_INITIALIZE no autentica credenciales ni concede autorizaciones.
  fnd_global.apps_initialize(
    user_id      => :p_user_id,
    resp_id      => :p_resp_id,
    resp_appl_id => :p_resp_appl_id);
  dbms_output.put_line('Contexto inicializado: usuario ' || fnd_global.user_id
    || ', responsabilidad ' || fnd_global.resp_id
    || ', aplicación ' || fnd_global.resp_appl_id);
END;
/
