/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : organizaciones.sql                                          ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Unidades organizativas vigentes y traducciones.             ║
║  Obligatorios   :                                                             ║
║    p_business_group_id (NUMBER).                                              ║
║    p_fecha_corte (VARCHAR2(10), YYYY-MM-DD).                                  ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_organization_id (NUMBER).                                                ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Sin contexto de sesión. Pendiente ejecución en EBS.         ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Catálogo de unidades, no árbol jerárquico ni clasificación de unidades operativas.
SELECT
    haou.business_group_id, haou.organization_id,
    haou.name nombre_base, haout.name nombre_traducido,
    haou.date_from, haou.date_to, haou.location_id,
    haou.type, haou.internal_external_flag
FROM hr_all_organization_units haou, hr_all_organization_units_tl haout
WHERE haou.business_group_id = :p_business_group_id
    AND :p_language IS NOT NULL
    AND haou.organization_id = haout.organization_id(+)
    AND haout.language(+) = :p_language
    AND haou.date_from <= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD')
    AND (haou.date_to IS NULL OR haou.date_to >= TO_DATE(:p_fecha_corte, 'YYYY-MM-DD'))
    AND (:p_organization_id IS NULL OR haou.organization_id = :p_organization_id)
ORDER BY haou.organization_id;
