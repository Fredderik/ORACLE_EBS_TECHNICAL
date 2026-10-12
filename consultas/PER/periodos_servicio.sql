/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : periodos_servicio.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Historial de períodos de empleo de una persona.             ║
║  Obligatorios   :                                                             ║
║    p_business_group_id (NUMBER).                                              ║
║    p_person_id (NUMBER).                                                      ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_period_of_service_id (NUMBER).                                           ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Sin contexto de sesión. Pendiente ejecución en EBS.         ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por período de servicio, incluidas bajas y recontrataciones.
-- No se une a todas las versiones de PER_ALL_PEOPLE_F para evitar duplicados.
-- No aplica fecha de corte: devuelve el historial del empleado seleccionado.
-- Trabajadores contingentes utilizan PER_PERIODS_OF_PLACEMENT, fuera de este script.
SELECT
    ppos.business_group_id, ppos.person_id, ppos.period_of_service_id,
    ppos.date_start, ppos.actual_termination_date,
    ppos.accepted_termination_date, ppos.notified_termination_date,
    ppos.projected_termination_date, ppos.last_standard_process_date,
    ppos.final_process_date, ppos.leaving_reason
FROM per_periods_of_service ppos
WHERE ppos.business_group_id = :p_business_group_id
    AND ppos.person_id = :p_person_id
    AND (:p_period_of_service_id IS NULL OR ppos.period_of_service_id = :p_period_of_service_id)
ORDER BY ppos.date_start, ppos.period_of_service_id;
