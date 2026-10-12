/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : solicitudes.sql                                                          ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Datos del ejemplo XML Publisher.                                         ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_application_id NUMBER: aplicación del programa.                                         ║
║ p_fecha_desde, p_fecha_hasta VARCHAR2: YYYY-MM-DD, días inclusivos.                       ║
║ p_language VARCHAR2: idioma EBS, por ejemplo US.                                          ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

SELECT fcr.request_id SOLICITUD_ID,
       NVL(fcpt.user_concurrent_program_name,
           TO_CHAR(fcr.concurrent_program_id)) PROGRAMA,
       fcr.phase_code FASE,
       fcr.status_code ESTADO,
       TO_CHAR(fcr.request_date, 'YYYY-MM-DD HH24:MI:SS') FECHA_SOLICITUD
FROM fnd_concurrent_requests fcr,
     fnd_concurrent_programs_tl fcpt
WHERE fcr.program_application_id = :p_application_id
  AND fcr.request_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD')
  AND fcr.request_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1
  AND fcpt.application_id(+) = fcr.program_application_id
  AND fcpt.concurrent_program_id(+) = fcr.concurrent_program_id
  AND fcpt.language(+) = :p_language
ORDER BY fcr.request_id;
