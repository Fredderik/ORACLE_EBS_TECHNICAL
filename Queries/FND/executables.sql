/*
╔══════════════════════════════════════════════════════════════════════╗
║  File Name      : executables.sql                                    ║
║  Author         : Freddy E. Aparicio M.                              ║
║  Creation Date  : 09/10/2026                                         ║
║  Version        : 1.0                                                ║
║  Description    : Executable details.                                ║
║                                                                      ║
║  Parameters     : Enter bind values explicitly; no session defaults. ║
║    - Required:                                                       ║
║      * p_language (EBS language code, e.g. US)                       ║
║      * p_security_group_id (lookup group, usually 0)                 ║
║    - Optionals (NULL means no filter):                               ║
║      * p_application_id                                              ║
║      * p_executable_id                                               ║
║      * p_executable_name                                             ║
║      * p_user_executable_name                                        ║
║                                                                      ║
║  Notes          : Target: Oracle EBS R12 onwards.                    ║
║                   Base table names and explicit TL joins.            ║
║                   Declare all binds before running in SQL*Plus.      ║
║                   Runtime validation in EBS is still required.       ║
║                                                                      ║
║  Updates        :                                                    ║
║    - 09/10/2026: Creation - Freddy E. Aparicio M.                    ║
╚══════════════════════════════════════════════════════════════════════╝
*/

SELECT
    fe.application_id,
    fe.executable_id,
    fet.language,
    fet.user_executable_name,
    fe.executable_name,
    fet.description,
    fe.execution_method_code,
    flv.meaning execution_method,
    fe.execution_file_name
FROM
    fnd_executables    fe,
    fnd_executables_tl fet,
    fnd_lookup_values flv
WHERE
        1 = 1
    AND fe.application_id = fet.application_id
    AND fe.executable_id = fet.executable_id
    AND fet.language = :p_language
    AND flv.language = fet.language
    AND flv.lookup_code = fe.execution_method_code
    AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
    AND flv.view_application_id = 0
    AND flv.security_group_id = :p_security_group_id
    --User parameters optional from Executable
    AND fe.application_id = nvl(:p_application_id, fe.application_id)
    AND fe.executable_id = nvl(:p_executable_id, fe.executable_id)
    AND fe.executable_name = nvl(:p_executable_name, fe.executable_name)
    AND fet.user_executable_name = nvl(:p_user_executable_name, fet.user_executable_name)
ORDER BY
    fe.application_id,
    fe.executable_name,
    fe.executable_id;
