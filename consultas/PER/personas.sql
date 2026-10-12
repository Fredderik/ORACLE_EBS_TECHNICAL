/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : personas.sql                                                ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Personas vigentes a la fecha de corte.                      ║
║  Obligatorios   :                                                             ║
║    p_business_group_id (NUMBER).                                              ║
║    p_fecha_corte (VARCHAR2(10), YYYY-MM-DD).                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_person_id (NUMBER).                                                      ║
║    p_employee_number (VARCHAR2(30)).                                          ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Sin contexto de sesión. Pendiente ejecución en EBS.         ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila DateTrack por persona; no se limita a empleados activos.
-- START_DATE es el inicio del registro personal, no necesariamente la contratación.
SELECT
    papf.business_group_id, papf.person_id, papf.employee_number,
    papf.full_name, papf.first_name, papf.last_name,
    papf.person_type_id, papf.current_employee_flag,
    papf.current_applicant_flag, papf.start_date,
    papf.effective_start_date, papf.effective_end_date
FROM per_all_people_f papf
WHERE papf.business_group_id = :p_business_group_id
    AND TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
        BETWEEN papf.effective_start_date AND papf.effective_end_date
    AND (:p_person_id IS NULL OR papf.person_id = :p_person_id)
    AND (:p_employee_number IS NULL OR papf.employee_number = :p_employee_number)
ORDER BY papf.full_name, papf.person_id;
