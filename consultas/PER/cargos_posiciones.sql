/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : cargos_posiciones.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Catálogos de cargos y posiciones.                           ║
║  Obligatorios   :                                                             ║
║    p_business_group_id (NUMBER).                                              ║
║    p_fecha_corte (VARCHAR2(10), YYYY-MM-DD).                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_job_id (NUMBER).                                                         ║
║    p_position_id (NUMBER).                                                    ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Sin contexto de sesión. Pendiente ejecución en EBS.         ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Cargos (jobs). NAME es el nombre base del flexfield, sin traducción.
-- p_position_id solo afecta al segundo resultado.
SELECT
    pj.business_group_id, pj.job_id, pj.name nombre_base_cargo,
    pj.job_definition_id, pj.job_group_id, pj.date_from, pj.date_to
FROM per_jobs pj
WHERE pj.business_group_id = :p_business_group_id
    AND pj.date_from <= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
    AND (pj.date_to IS NULL OR pj.date_to >= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD'))
    AND (:p_job_id IS NULL OR pj.job_id = :p_job_id)
ORDER BY pj.job_id
/
-- 2. Posiciones: versión DateTrack para la fecha de corte.
-- Vigencia del registro no equivale a disponibilidad para cubrir la posición.
SELECT
    hapf.business_group_id, hapf.position_id, hapf.name nombre_base_posicion,
    hapf.job_id, hapf.organization_id, hapf.location_id,
    hapf.position_definition_id, hapf.availability_status_id,
    hapf.effective_start_date, hapf.effective_end_date
FROM hr_all_positions_f hapf
WHERE hapf.business_group_id = :p_business_group_id
    AND TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
        BETWEEN hapf.effective_start_date AND hapf.effective_end_date
    AND (:p_job_id IS NULL OR hapf.job_id = :p_job_id)
    AND (:p_position_id IS NULL OR hapf.position_id = :p_position_id)
ORDER BY hapf.position_id;
