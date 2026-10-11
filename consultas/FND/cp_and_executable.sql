/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : cp_and_executable.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 23/03/2025                                                  ║
║  Versión        : 1.3                                                         ║
║  Descripción    : Concurrentes, ejecutables y parámetros.                     ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    - Obligatorios:                                                            ║
║      * p_language (código de idioma EBS; por ejemplo, US)                     ║
║      * p_security_group_id (grupo de seguridad; normalmente 0)                ║
║    - Opcionales (NULL omite el filtro, salvo indicación):                     ║
║      * p_application_id (aplicación del concurrente)                          ║
║      * p_concurrent_program_name                                              ║
║      * p_user_concurrent_program_name                                         ║
║      * p_concurrent_program_id                                                ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; nombres de tablas base.         ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin valores predeterminados del contexto de sesión.         ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                   Declarar todas las variables antes de ejecutar en SQL*Plus. ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    23/03/2025: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    09/10/2026: Versión 1.1. Consulta de parámetros y grupo explícito.         ║
║                Unión completa del ejecutable; alcance R12.                    ║
║    10/10/2026: Versión 1.2. Comentarios y cabecera en español.                ║
║    11/10/2026: Versión 1.3. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

--Consulta 1: Programa concurrente y su ejecutable.
--La barra / ejecuta este SELECT una vez; no añadir punto y coma antes.
SELECT
    fcp.application_id,
    fcp.concurrent_program_id,
    fcpt.language,
    fcp.enabled_flag,
    fcpt.user_concurrent_program_name,
    fcp.concurrent_program_name,
    fe.application_id executable_application_id,
    fe.executable_id,
    fet.user_executable_name,
    fe.executable_name,
    fe.execution_method_code,
    flv.meaning execution_method,
    fe.execution_file_name
FROM
    fnd_concurrent_programs_tl fcpt,
    fnd_concurrent_programs    fcp,
    fnd_executables_tl         fet,
    fnd_executables            fe,
    fnd_lookup_values          flv
WHERE
        1 = 1
    AND fcp.application_id = fcpt.application_id
    AND fcp.concurrent_program_id = fcpt.concurrent_program_id
    AND fe.application_id = fet.application_id
    AND fe.executable_id = fet.executable_id
    AND fcp.executable_application_id = fe.application_id
    AND fcp.executable_id = fe.executable_id
    AND fcpt.language = fet.language
    AND flv.language = fet.language
    AND flv.lookup_code = fe.execution_method_code
    AND flv.view_application_id = 0
    AND flv.security_group_id = :p_security_group_id
    AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
    AND fcpt.language = :p_language
    --Filtros opcionales del programa concurrente.
    AND fcp.application_id = nvl(:p_application_id, fcp.application_id)
    AND fcp.concurrent_program_name = nvl(:p_concurrent_program_name, fcp.concurrent_program_name)
    AND fcpt.user_concurrent_program_name = nvl(:p_user_concurrent_program_name, fcpt.user_concurrent_program_name)
    AND fcp.concurrent_program_id = nvl(:p_concurrent_program_id, fcp.concurrent_program_id)
ORDER BY
    fcp.application_id,
    fcp.concurrent_program_name,
    fcp.concurrent_program_id
/
--Consulta 2: Parámetros de la misma selección de programas concurrentes.
--Incluye parámetros habilitados y deshabilitados. Los programas sin
--parámetros no generan filas. El grupo de seguridad solo se usa en la consulta 1.
SELECT
    fcp.application_id,
    fcp.concurrent_program_id,
    fcpt.language,
    fcp.concurrent_program_name,
    fcpt.user_concurrent_program_name,
    fdfcu.descriptive_flex_context_code,
    fdfcu.column_seq_num parameter_sequence,
    fdfcu.application_column_name,
    fdfcu.end_user_column_name parameter_name,
    fdfcut.form_left_prompt parameter_prompt,
    fdfcut.description parameter_description,
    fdfcu.enabled_flag,
    fdfcu.required_flag,
    fdfcu.display_flag,
    fdfcu.default_type,
    fdfcu.default_value,
    fdfcu.srw_param parameter_token,
    fdfcu.flex_value_set_id,
    ffvs.flex_value_set_name
FROM
    fnd_concurrent_programs    fcp,
    fnd_concurrent_programs_tl fcpt,
    fnd_descr_flex_column_usages fdfcu,
    fnd_descr_flex_col_usage_tl  fdfcut,
    fnd_flex_value_sets         ffvs
WHERE
        1 = 1
    AND fcp.application_id = fcpt.application_id
    AND fcp.concurrent_program_id = fcpt.concurrent_program_id
    AND fdfcu.application_id = fcp.application_id
    AND fdfcu.descriptive_flexfield_name = '$SRS$.' || fcp.concurrent_program_name
    AND fdfcut.application_id = fdfcu.application_id
    AND fdfcut.descriptive_flexfield_name = fdfcu.descriptive_flexfield_name
    AND fdfcut.descriptive_flex_context_code = fdfcu.descriptive_flex_context_code
    AND fdfcut.application_column_name = fdfcu.application_column_name
    AND fdfcut.language = fcpt.language
    AND fdfcu.flex_value_set_id = ffvs.flex_value_set_id(+)
    AND fcpt.language = :p_language
    --Los mismos filtros opcionales del concurrente que en la consulta 1.
    AND fcp.application_id = nvl(:p_application_id, fcp.application_id)
    AND fcp.concurrent_program_name = nvl(:p_concurrent_program_name, fcp.concurrent_program_name)
    AND fcpt.user_concurrent_program_name = nvl(:p_user_concurrent_program_name, fcpt.user_concurrent_program_name)
    AND fcp.concurrent_program_id = nvl(:p_concurrent_program_id, fcp.concurrent_program_id)
ORDER BY
    fcp.application_id,
    fcp.concurrent_program_name,
    fcp.concurrent_program_id,
    fdfcu.descriptive_flex_context_code,
    fdfcu.column_seq_num,
    fdfcu.application_column_name;
