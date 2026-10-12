/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : incompatibilidades.sql                                                   ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Reglas y solicitudes potencialmente incompatibles.                       ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_request_id NUMBER: solicitud a analizar.                                                ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por regla y solicitud en fase R; conserva reglas sin candidata.
-- No demuestra un bloqueo: revisar dominio, alcance y configuración.
-- Se excluye la propia solicitud; puede existir incompatibilidad consigo mismo.
SELECT fcr.request_id solicitud_analizada,
       fcr.phase_code fase_analizada,
       fcr.status_code estado_analizado,
       fcps.running_application_id aplicacion_incompatible_id,
       fcps.running_concurrent_program_id programa_incompatible_id,
       fcr_candidata.request_id solicitud_candidata,
       fcr_candidata.status_code estado_candidata,
       fcr_candidata.actual_start_date inicio_candidata
FROM fnd_concurrent_requests fcr,
     fnd_concurrent_program_serial fcps,
     fnd_concurrent_requests fcr_candidata
WHERE fcr.request_id = :p_request_id
  AND fcps.to_run_application_id = fcr.program_application_id
  AND fcps.to_run_concurrent_program_id = fcr.concurrent_program_id
  AND fcr_candidata.program_application_id(+) = fcps.running_application_id
  AND fcr_candidata.concurrent_program_id(+) = fcps.running_concurrent_program_id
  AND fcr_candidata.phase_code(+) = 'R'
  AND fcr_candidata.request_id(+) <> :p_request_id
ORDER BY fcps.running_application_id,
         fcps.running_concurrent_program_id,
         fcr_candidata.request_id;
