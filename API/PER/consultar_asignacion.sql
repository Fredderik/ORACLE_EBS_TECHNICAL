/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : consultar_asignacion.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Registro efectivo e historial para preparar una actualización.
║ NUMBER: p_business_group_id, p_assignment_id (obligatorios).
║ VARCHAR2: p_effective_date, obligatoria, YYYY-MM-DD.
║ R12.1/R12.2. Pendiente ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
-- 1. Copiar el OVN del registro efectivo; no usar MAX(OVN) del historial.
SELECT paaf.assignment_id, paaf.person_id, paaf.assignment_number,
       paaf.business_group_id, paaf.assignment_type, paaf.supervisor_id,
       paaf.object_version_number, paaf.effective_start_date, paaf.effective_end_date
FROM per_all_assignments_f paaf
WHERE paaf.business_group_id = :p_business_group_id
  AND paaf.assignment_id = :p_assignment_id
  AND paaf.assignment_type = 'E'
  AND TO_DATE(:p_effective_date, 'FXYYYY-MM-DD')
      BETWEEN paaf.effective_start_date AND paaf.effective_end_date
/

-- 2. Revisar también los cambios futuros antes de elegir el modo DateTrack.
SELECT paaf.assignment_id, paaf.supervisor_id, paaf.object_version_number,
       paaf.effective_start_date, paaf.effective_end_date
FROM per_all_assignments_f paaf
WHERE paaf.business_group_id = :p_business_group_id
  AND paaf.assignment_id = :p_assignment_id
  AND paaf.assignment_type = 'E'
ORDER BY paaf.effective_start_date
/
