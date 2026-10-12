/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : asignaciones.sql                                            ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Asignaciones y supervisor a la fecha indicada.              ║
║  Obligatorios   :                                                             ║
║    p_business_group_id (NUMBER).                                              ║
║    p_fecha_corte (VARCHAR2(10), YYYY-MM-DD).                                  ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_person_id (NUMBER).                                                      ║
║    p_assignment_id (NUMBER).                                                  ║
║    p_assignment_type (VARCHAR2(1)).                                           ║
║    p_primary_flag (VARCHAR2(1)).                                              ║
║    p_organization_id (NUMBER).                                                ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Sin contexto de sesión. Pendiente ejecución en EBS.         ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por asignación vigente; una persona puede tener varias.
-- PRIMARY_FLAG no garantiza que la asignación esté laboralmente activa.
-- Los nombres de organización traducidos no tienen historial DateTrack.
SELECT
    paaf.business_group_id, papf.person_id, papf.employee_number,
    papf.full_name, paaf.assignment_id, paaf.assignment_number,
    paaf.assignment_type, paaf.primary_flag, paaf.assignment_status_type_id,
    paaf.effective_start_date, paaf.effective_end_date,
    paaf.organization_id, haout.name nombre_organizacion,
    paaf.job_id, paaf.position_id, paaf.grade_id, paaf.location_id,
    paaf.payroll_id, paaf.period_of_service_id,
    paaf.supervisor_id, papf_sup.full_name nombre_supervisor
FROM per_all_assignments_f paaf, per_all_people_f papf,
     hr_all_organization_units_tl haout, per_all_people_f papf_sup
WHERE paaf.business_group_id = :p_business_group_id
    AND :p_language IS NOT NULL
    AND paaf.person_id = papf.person_id
    AND paaf.business_group_id = papf.business_group_id
    AND TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
        BETWEEN paaf.effective_start_date AND paaf.effective_end_date
    AND TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
        BETWEEN papf.effective_start_date AND papf.effective_end_date
    AND paaf.organization_id = haout.organization_id(+)
    AND haout.language(+) = :p_language
    AND paaf.supervisor_id = papf_sup.person_id(+)
    AND papf_sup.effective_start_date(+) <= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
    AND papf_sup.effective_end_date(+) >= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
    AND (:p_person_id IS NULL OR paaf.person_id = :p_person_id)
    AND (:p_assignment_id IS NULL OR paaf.assignment_id = :p_assignment_id)
    AND (:p_assignment_type IS NULL OR paaf.assignment_type = :p_assignment_type)
    AND (:p_primary_flag IS NULL OR paaf.primary_flag = :p_primary_flag)
    AND (:p_organization_id IS NULL OR paaf.organization_id = :p_organization_id)
ORDER BY papf.person_id, paaf.assignment_id;
