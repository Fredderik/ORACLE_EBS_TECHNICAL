/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : gestor_solicitud.sql                                                     ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Gestor e identificadores de sesión registrados.                          ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_request_id NUMBER: solicitud.                                                           ║
║ p_language VARCHAR2: idioma EBS explícito, por ejemplo US.                                ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por solicitud. Metadatos actuales del gestor.
-- ORACLE_SESSION_ID es AUDSID, no SID. No prueba que la sesión siga viva.
-- Los identificadores de la solicitud y del gestor representan procesos distintos.
SELECT fcr.request_id solicitud_id,
       fcr.phase_code fase_codigo,
       fcr.status_code estado_codigo,
       fcr.hold_flag retenida,
       fcr.priority prioridad,
       fcr.requested_start_date inicio_programado,
       fcr.controlling_manager proceso_gestor_id,
       fcr.oracle_session_id audsid_solicitud,
       fcr.oracle_process_id proceso_oracle_solicitud,
       fcr.os_process_id proceso_so_solicitud,
       fcr.ops_instance instancia_solicitud,
       fcpr.process_status_code estado_proceso_gestor,
       fcpr.process_start_date inicio_proceso_gestor,
       fcpr.session_id sesion_registrada_gestor,
       fcpr.oracle_process_id proceso_oracle_gestor,
       fcpr.node_name nodo_gestor,
       fcpr.instance_number instancia_gestor,
       fcpr.logfile_name log_gestor,
       fcq.application_id aplicacion_cola_id,
       fcq.concurrent_queue_id cola_id,
       fcq.concurrent_queue_name cola_codigo,
       fcqt.user_concurrent_queue_name cola_nombre,
       fcq.max_processes procesos_objetivo,
       fcq.running_processes procesos_registrados,
       fcq.sleep_seconds intervalo_segundos,
       fcq.control_code control_codigo
FROM fnd_concurrent_requests fcr,
     fnd_concurrent_processes fcpr,
     fnd_concurrent_queues fcq,
     fnd_concurrent_queues_tl fcqt
WHERE fcr.request_id = :p_request_id
  AND fcpr.concurrent_process_id(+) = fcr.controlling_manager
  AND fcq.application_id(+) = fcpr.queue_application_id
  AND fcq.concurrent_queue_id(+) = fcpr.concurrent_queue_id
  AND fcqt.application_id(+) = fcq.application_id
  AND fcqt.concurrent_queue_id(+) = fcq.concurrent_queue_id
  AND fcqt.language(+) = :p_language;
