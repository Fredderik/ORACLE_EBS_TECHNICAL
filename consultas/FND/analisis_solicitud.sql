/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : analisis_solicitud.sql                                      ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
    r.request_id                         solicitud_id,
    r.parent_request_id                  solicitud_padre_id,
    r.program_application_id             aplicacion_programa_id,
    r.concurrent_program_id              programa_id,
    cp.concurrent_program_name           programa_corto,
    cpt.user_concurrent_program_name      programa_nombre,
    e.application_id                     aplicacion_ejecutable_id,
    e.executable_id                      ejecutable_id,
    e.executable_name                    ejecutable_corto,
    et.user_executable_name              ejecutable_nombre,
    e.execution_file_name                fuente_registrada,
    e.subroutine_name                    subrutina_registrada,
    e.execution_method_code              metodo_codigo,
    m.meaning                            metodo_ejecucion,
    r.responsibility_application_id       aplicacion_responsabilidad_id,
    r.responsibility_id                  responsabilidad_id,
    rt.responsibility_name               responsabilidad_nombre,
    r.requested_by                       usuario_id,
    u.user_name                          usuario,
    r.phase_code                         fase_codigo,
    CASE r.phase_code
        WHEN 'P' THEN 'Pendiente'
        WHEN 'R' THEN 'En ejecución'
        WHEN 'C' THEN 'Completada'
        WHEN 'I' THEN 'Inactiva'
        ELSE 'Fase no reconocida'
    END                                  fase,
    r.status_code                        estado_codigo,
    st.meaning                           estado,
    r.request_date                       fecha_solicitud,
    r.requested_start_date               inicio_programado,
    r.actual_start_date                  inicio_real,
    r.actual_completion_date             fin_real,
    SYSDATE                              fecha_consulta,
    CASE
        WHEN r.phase_code = 'R'
         AND r.actual_start_date IS NOT NULL
         AND r.actual_completion_date IS NULL
        THEN ROUND((SYSDATE - r.actual_start_date) * 86400)
    END                                  en_ejecucion_segundos,
    CASE
        WHEN r.phase_code = 'R'
         AND r.actual_start_date IS NOT NULL
         AND r.actual_completion_date IS NULL
        THEN ROUND((SYSDATE - r.actual_start_date) * 1440, 2)
    END                                  en_ejecucion_minutos,
    CASE
        WHEN r.actual_start_date IS NOT NULL
         AND r.actual_completion_date IS NOT NULL
        THEN ROUND((r.actual_completion_date - r.actual_start_date) * 86400)
    END                                  duracion_total_segundos,
    CASE
        WHEN r.actual_start_date IS NOT NULL
         AND r.actual_completion_date IS NOT NULL
        THEN ROUND((r.actual_completion_date - r.actual_start_date) * 1440, 2)
    END                                  duracion_total_minutos,
    r.completion_text                    mensaje_finalizacion,
    r.logfile_name                       archivo_log,
    r.logfile_node_name                  nodo_log,
    r.outfile_name                       archivo_salida,
    r.outfile_node_name                  nodo_salida
FROM
    fnd_concurrent_requests    r,
    fnd_concurrent_programs    cp,
    fnd_concurrent_programs_tl cpt,
    fnd_executables            e,
    fnd_executables_tl         et,
    fnd_responsibility_tl      rt,
    fnd_user                   u,
    fnd_lookup_values          m,
    fnd_lookup_values          st
WHERE
        r.request_id = :p_request_id
    AND r.program_application_id = cp.application_id(+)
    AND r.concurrent_program_id = cp.concurrent_program_id(+)
    AND cp.application_id = cpt.application_id(+)
    AND cp.concurrent_program_id = cpt.concurrent_program_id(+)
    AND cpt.language(+) = :p_language
    AND cp.executable_application_id = e.application_id(+)
    AND cp.executable_id = e.executable_id(+)
    AND e.application_id = et.application_id(+)
    AND e.executable_id = et.executable_id(+)
    AND et.language(+) = :p_language
    AND r.responsibility_application_id = rt.application_id(+)
    AND r.responsibility_id = rt.responsibility_id(+)
    AND rt.language(+) = :p_language
    AND r.requested_by = u.user_id(+)
    AND e.execution_method_code = m.lookup_code(+)
    AND m.lookup_type(+) = 'CP_EXECUTION_METHOD_CODE'
    AND m.view_application_id(+) = 0
    AND m.security_group_id(+) = :p_security_group_id
    AND m.language(+) = :p_language
    AND r.status_code = st.lookup_code(+)
    AND st.lookup_type(+) = 'CP_STATUS_CODE'
    AND st.view_application_id(+) = 0
    AND st.security_group_id(+) = :p_security_group_id
    AND st.language(+) = :p_language;
