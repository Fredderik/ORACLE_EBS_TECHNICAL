/*
╔══════════════════════════════════════════════════════════════════════╗
║  File Name      : cp_and_executable.sql                              ║
║  Author         : Freddy E. Aparicio M.                              ║
║  Creation Date  : 23/03/2025                                         ║
║  Version        : 1.1                                                ║
║  Description    : Concurrent, executable and parameter details.      ║
║                                                                      ║
║  Parameters     : Enter bind values explicitly; no session defaults. ║
║    - Required:                                                       ║
║      * p_language (EBS language code, e.g. US)                       ║
║      * p_security_group_id (lookup group, usually 0)                 ║
║    - Optionals (NULL means no filter):                               ║
║      * p_application_id (concurrent program application)             ║
║      * p_concurrent_program_name                                     ║
║      * p_user_concurrent_program_name                                ║
║      * p_concurrent_program_id                                       ║
║                                                                      ║
║  Notes          : Target: Oracle EBS R12 onwards.                    ║
║                   Base table names and explicit TL joins.            ║
║                   Declare all binds before running in SQL*Plus.      ║
║                   Runtime validation in EBS is still required.       ║
║                                                                      ║
║  Updates        :                                                    ║
║    - 23/03/2025: Creation - Freddy E. Aparicio M.                    ║
║    - 09/10/2026: Parameter query and explicit lookup security group. ║
║    -             Complete executable join; R12 scope.                ║
╚══════════════════════════════════════════════════════════════════════╝
*/

--Query 1: Concurrent program and its executable.
--The slash executes this SELECT once; do not add a semicolon before it.
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
    --User parameters optional from Concurrent program
    AND fcp.application_id = nvl(:p_application_id, fcp.application_id)
    AND fcp.concurrent_program_name = nvl(:p_concurrent_program_name, fcp.concurrent_program_name)
    AND fcpt.user_concurrent_program_name = nvl(:p_user_concurrent_program_name, fcpt.user_concurrent_program_name)
    AND fcp.concurrent_program_id = nvl(:p_concurrent_program_id, fcp.concurrent_program_id)
ORDER BY
    fcp.application_id,
    fcp.concurrent_program_name,
    fcp.concurrent_program_id
/
--Query 2: Parameters defined for the same concurrent program selection.
--Includes enabled and disabled parameters; programs without parameters
--have no rows here. The security group bind is only used by Query 1.
SELECT
    fcp.application_id,
    fcp.concurrent_program_id,
    fcpt.language,
    fcp.concurrent_program_name,
    fcpt.user_concurrent_program_name,
    fcu.descriptive_flex_context_code,
    fcu.column_seq_num parameter_sequence,
    fcu.application_column_name,
    fcu.end_user_column_name parameter_name,
    fcut.form_left_prompt parameter_prompt,
    fcut.description parameter_description,
    fcu.enabled_flag,
    fcu.required_flag,
    fcu.display_flag,
    fcu.default_type,
    fcu.default_value,
    fcu.srw_param parameter_token,
    fcu.flex_value_set_id,
    fvs.flex_value_set_name
FROM
    fnd_concurrent_programs    fcp,
    fnd_concurrent_programs_tl fcpt,
    fnd_descr_flex_column_usages fcu,
    fnd_descr_flex_col_usage_tl  fcut,
    fnd_flex_value_sets         fvs
WHERE
        1 = 1
    AND fcp.application_id = fcpt.application_id
    AND fcp.concurrent_program_id = fcpt.concurrent_program_id
    AND fcu.application_id = fcp.application_id
    AND fcu.descriptive_flexfield_name = '$SRS$.' || fcp.concurrent_program_name
    AND fcut.application_id = fcu.application_id
    AND fcut.descriptive_flexfield_name = fcu.descriptive_flexfield_name
    AND fcut.descriptive_flex_context_code = fcu.descriptive_flex_context_code
    AND fcut.application_column_name = fcu.application_column_name
    AND fcut.language = fcpt.language
    AND fcu.flex_value_set_id = fvs.flex_value_set_id(+)
    AND fcpt.language = :p_language
    --Same optional Concurrent program filters as Query 1
    AND fcp.application_id = nvl(:p_application_id, fcp.application_id)
    AND fcp.concurrent_program_name = nvl(:p_concurrent_program_name, fcp.concurrent_program_name)
    AND fcpt.user_concurrent_program_name = nvl(:p_user_concurrent_program_name, fcpt.user_concurrent_program_name)
    AND fcp.concurrent_program_id = nvl(:p_concurrent_program_id, fcp.concurrent_program_id)
ORDER BY
    fcp.application_id,
    fcp.concurrent_program_name,
    fcp.concurrent_program_id,
    fcu.descriptive_flex_context_code,
    fcu.column_seq_num,
    fcu.application_column_name;
