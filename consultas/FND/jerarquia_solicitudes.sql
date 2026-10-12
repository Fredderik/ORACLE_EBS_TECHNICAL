/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : jerarquia_solicitudes.sql                                                ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Padres y solicitudes dependientes.                                       ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_request_id NUMBER: solicitud inicial.                                                   ║
║ p_max_niveles NUMBER: entero positivo; 1 muestra solo la inicial.                         ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Descendientes. Incluye la solicitud inicial en el nivel 1.
-- NOCYCLE evita continuar un ciclo; revisar ciclo_detectado = 1.
SELECT LEVEL nivel,
       CONNECT_BY_ISCYCLE ciclo_detectado,
       fcr.request_id solicitud_id,
       fcr.parent_request_id solicitud_padre_id,
       fcr.program_application_id aplicacion_programa_id,
       fcr.concurrent_program_id programa_id,
       fcr.phase_code fase_codigo,
       fcr.status_code estado_codigo,
       fcr.actual_start_date inicio_real,
       fcr.actual_completion_date fin_real
FROM fnd_concurrent_requests fcr
START WITH fcr.request_id = :p_request_id
       AND :p_max_niveles >= 1
CONNECT BY NOCYCLE PRIOR fcr.request_id = fcr.parent_request_id
       AND LEVEL <= :p_max_niveles
ORDER SIBLINGS BY fcr.request_id
/
-- Ancestros. El nivel 2 es el padre inmediato, no otro descendiente.
SELECT LEVEL nivel,
       CONNECT_BY_ISCYCLE ciclo_detectado,
       fcr.request_id solicitud_id,
       fcr.parent_request_id solicitud_padre_id,
       fcr.phase_code fase_codigo,
       fcr.status_code estado_codigo
FROM fnd_concurrent_requests fcr
START WITH fcr.request_id = :p_request_id
       AND :p_max_niveles >= 1
CONNECT BY NOCYCLE PRIOR fcr.parent_request_id = fcr.request_id
       AND LEVEL <= :p_max_niveles;
