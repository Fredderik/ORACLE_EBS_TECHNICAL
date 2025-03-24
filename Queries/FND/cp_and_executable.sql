/*
╔═════════════════════════════════════════════════════════════════════╗
║  File Name      : cp_and_executable.sql                             ║
║  Author         : Freddy E. Aparicio M.                             ║
║  Creation Date  : 23/03/2025                                        ║
║  Version        : 1.0                                               ║
║  Description    : Main details of the concurrent and executable.    ║
║                                                                     ║
║  Parameters     : The parameters are based on information from the  ║
║                   concurrent program.                               ║
║     - Optionals:                                                    ║
║       * p_language                                                  ║
║       * p_concurrent_program_name                                   ║
║       * p_user_concurrent_program_name                              ║
║       * p_concurrent_program_id                                     ║
║                                                                     ║
║  Notes          : Compatible with Oracle EBS R11 and R12.           ║
║                                                                     ║
║  Updates        :                                                   ║
║     - 23/03/2025: Creation - Freddy E. Aparicio M.                  ║
╚═════════════════════════════════════════════════════════════════════╝
*/

/
SELECT
    fcp.enabled_flag,
    fcpt.user_concurrent_program_name,
    fcp.concurrent_program_name,
    fet.user_executable_name,
    fe.executable_name,
    fe.execution_method_code,
    flv.meaning,
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
    AND fcp.executable_id = fe.executable_id
    AND fcpt.language = fet.language
    AND flv.language = fet.language
    AND flv.lookup_code = fe.execution_method_code
    AND flv.view_application_id = 0
    AND flv.security_group_id = fnd_global.lookup_security_group(flv.lookup_type, flv.view_application_id)
    AND UPPER(flv.lookup_type) = 'CP_EXECUTION_METHOD_CODE'
    --User parameters optional from Concurrent program
    AND fcpt.language = nvl(:p_language, fcpt.language)
    AND fcp.concurrent_program_name = nvl(:p_concurrent_program_name, fcp.concurrent_program_name)
    AND fcpt.user_concurrent_program_name = nvl(:p_user_concurrent_program_name, fcpt.user_concurrent_program_name)
    AND fcp.concurrent_program_id = nvl(:p_concurrent_program_id, fcp.concurrent_program_id); 
/