/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : analisis_solicitud.sql                                      ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Análisis de una ejecución concurrente.                      ║
║                                                                               ║
║  Parámetros obligatorios (variables de enlace):                               ║
║    * p_request_id (NUMBER; identificador de la solicitud)                     ║
║    * p_language (código de idioma EBS; por ejemplo, US)                       ║
║    * p_security_group_id (grupo de los lookups; normalmente 0)                ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; tablas base y traducciones.     ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin valores predeterminados del contexto de sesión.         ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    10/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Declarar los tres parámetros antes de ejecutar en SQL*Plus.
-- Los tiempos son de reloj transcurrido; no representan consumo de CPU.
-- En ejecución: desde el inicio real hasta SYSDATE (reloj de la base).
-- Total: desde el inicio real hasta el fin, incluso si terminó con error.
-- Sin inicio real, ambos tiempos son NULL. La espera en cola no se incluye.
-- La fuente y el método corresponden a la definición ACTUAL del ejecutable;
-- no permiten reconstruir la versión del archivo utilizada históricamente.
-- Las uniones externas conservan la solicitud aunque falten metadatos.
SELECT
    fcr.request_id                         solicitud_id,
    fcr.parent_request_id                  solicitud_padre_id,
    fcr.program_application_id             aplicacion_programa_id,
    fcr.concurrent_program_id              programa_id,
    fcp.concurrent_program_name           programa_corto,
    fcpt.user_concurrent_program_name      programa_nombre,
    fe.application_id                     aplicacion_ejecutable_id,
    fe.executable_id                      ejecutable_id,
    fe.executable_name                    ejecutable_corto,
    fet.user_executable_name              ejecutable_nombre,
    fe.execution_file_name                fuente_registrada,
    fe.subroutine_name                    subrutina_registrada,
    fe.execution_method_code              metodo_codigo,
    flv_metodo.meaning                            metodo_ejecucion,
    fcr.responsibility_application_id       aplicacion_responsabilidad_id,
    fcr.responsibility_id                  responsabilidad_id,
    frt.responsibility_name               responsabilidad_nombre,
    fcr.requested_by                       usuario_id,
    fu.user_name                          usuario,
    fcr.phase_code                         fase_codigo,
    CASE fcr.phase_code
        WHEN 'P' THEN 'Pendiente'
        WHEN 'R' THEN 'En ejecución'
        WHEN 'C' THEN 'Completada'
        WHEN 'I' THEN 'Inactiva'
        ELSE 'Fase no reconocida'
    END                                  fase,
    fcr.status_code                        estado_codigo,
    flv_estado.meaning                           estado,
    fcr.request_date                       fecha_solicitud,
    fcr.requested_start_date               inicio_programado,
    fcr.actual_start_date                  inicio_real,
    fcr.actual_completion_date             fin_real,
    SYSDATE                              fecha_consulta,
    CASE
        WHEN fcr.phase_code = 'R'
         AND fcr.actual_start_date IS NOT NULL
         AND fcr.actual_completion_date IS NULL
        THEN ROUND((SYSDATE - fcr.actual_start_date) * 86400)
    END                                  en_ejecucion_segundos,
    CASE
        WHEN fcr.phase_code = 'R'
         AND fcr.actual_start_date IS NOT NULL
         AND fcr.actual_completion_date IS NULL
        THEN ROUND((SYSDATE - fcr.actual_start_date) * 1440, 2)
    END                                  en_ejecucion_minutos,
    CASE
        WHEN fcr.actual_start_date IS NOT NULL
         AND fcr.actual_completion_date IS NOT NULL
        THEN ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 86400)
    END                                  duracion_total_segundos,
    CASE
        WHEN fcr.actual_start_date IS NOT NULL
         AND fcr.actual_completion_date IS NOT NULL
        THEN ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 1440, 2)
    END                                  duracion_total_minutos,
    fcr.completion_text                    mensaje_finalizacion,
    fcr.logfile_name                       archivo_log,
    fcr.logfile_node_name                  nodo_log,
    fcr.outfile_name                       archivo_salida,
    fcr.outfile_node_name                  nodo_salida
FROM
    fnd_concurrent_requests    fcr,
    fnd_concurrent_programs    fcp,
    fnd_concurrent_programs_tl fcpt,
    fnd_executables            fe,
    fnd_executables_tl         fet,
    fnd_responsibility_tl      frt,
    fnd_user                   fu,
    fnd_lookup_values          flv_metodo,
    fnd_lookup_values          flv_estado
WHERE
        fcr.request_id = :p_request_id
    AND fcr.program_application_id = fcp.application_id(+)
    AND fcr.concurrent_program_id = fcp.concurrent_program_id(+)
    AND fcp.application_id = fcpt.application_id(+)
    AND fcp.concurrent_program_id = fcpt.concurrent_program_id(+)
    AND fcpt.language(+) = :p_language
    AND fcp.executable_application_id = fe.application_id(+)
    AND fcp.executable_id = fe.executable_id(+)
    AND fe.application_id = fet.application_id(+)
    AND fe.executable_id = fet.executable_id(+)
    AND fet.language(+) = :p_language
    AND fcr.responsibility_application_id = frt.application_id(+)
    AND fcr.responsibility_id = frt.responsibility_id(+)
    AND frt.language(+) = :p_language
    AND fcr.requested_by = fu.user_id(+)
    AND fe.execution_method_code = flv_metodo.lookup_code(+)
    AND flv_metodo.lookup_type(+) = 'CP_EXECUTION_METHOD_CODE'
    AND flv_metodo.view_application_id(+) = 0
    AND flv_metodo.security_group_id(+) = :p_security_group_id
    AND flv_metodo.language(+) = :p_language
    AND fcr.status_code = flv_estado.lookup_code(+)
    AND flv_estado.lookup_type(+) = 'CP_STATUS_CODE'
    AND flv_estado.view_application_id(+) = 0
    AND flv_estado.security_group_id(+) = :p_security_group_id
    AND flv_estado.language(+) = :p_language;
