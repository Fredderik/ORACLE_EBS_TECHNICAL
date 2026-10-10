/*
╔═══════════════════════════════════════════════════════════════════════╗
║  Archivo        : executables.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                               ║
║  Fecha creación : 09/10/2026                                          ║
║  Versión        : 1.1                                                 ║
║  Descripción    : Detalle de ejecutables.                             ║
║                                                                       ║
║  Parámetros     : Variables de enlace explícitas.                     ║
║    - Obligatorios:                                                    ║
║      * p_language (código de idioma EBS; por ejemplo, US)             ║
║      * p_security_group_id (grupo de seguridad; normalmente 0)        ║
║    - Opcionales (NULL omite el filtro, salvo indicación):             ║
║      * p_application_id                                               ║
║      * p_executable_id                                                ║
║      * p_executable_name                                              ║
║      * p_user_executable_name                                         ║
║                                                                       ║
║  Notas          : Oracle EBS R12 en adelante; nombres de tablas base. ║
║                   Uniones por igualdad en WHERE; externas con (+).    ║
║                   Sin valores predeterminados del contexto de sesión. ║
║                   Pendiente validación de ejecución en Oracle EBS.    ║
║                                                                       ║
║  Actualizaciones:                                                     ║
║    09/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.          ║
║    10/10/2026: Versión 1.1. Español y sintaxis SQL tradicional.       ║
╚═══════════════════════════════════════════════════════════════════════╝
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
    --Filtros opcionales del ejecutable.
    AND fe.application_id = nvl(:p_application_id, fe.application_id)
    AND fe.executable_id = nvl(:p_executable_id, fe.executable_id)
    AND fe.executable_name = nvl(:p_executable_name, fe.executable_name)
    AND fet.user_executable_name = nvl(:p_user_executable_name, fet.user_executable_name)
ORDER BY
    fe.application_id,
    fe.executable_name,
    fe.executable_id;
