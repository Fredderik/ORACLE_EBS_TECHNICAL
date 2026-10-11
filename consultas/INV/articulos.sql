/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : articulos.sql                                               ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Artículos por organización y controles de inventario.       ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorios: p_organization_id (NUMBER), p_language (texto EBS).            ║
║  Opcionales: p_inventory_item_id (NUMBER), p_segment1 (texto).                ║
║  Opcional texto: p_inventory_item_status_code.                                ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- La clave del artículo incluye INVENTORY_ITEM_ID y ORGANIZATION_ID.
-- SEGMENT1 no es necesariamente el código completo del artículo.
-- Se muestran los 20 segmentos sin asumir estructura ni separador del flexfield.
-- Se conservan artículos sin traducción para el idioma solicitado.
SELECT
    msib.organization_id, msib.inventory_item_id,
    msib.segment1, msib.segment2, msib.segment3, msib.segment4,
    msib.segment5, msib.segment6, msib.segment7, msib.segment8,
    msib.segment9, msib.segment10, msib.segment11, msib.segment12,
    msib.segment13, msib.segment14, msib.segment15, msib.segment16,
    msib.segment17, msib.segment18, msib.segment19, msib.segment20,
    msit.description descripcion_articulo,
    msit.long_description descripcion_larga,
    msib.primary_uom_code, msib.secondary_uom_code,
    msib.inventory_item_status_code, msib.item_type,
    msib.enabled_flag, msib.start_date_active, msib.end_date_active,
    msib.inventory_item_flag, msib.stock_enabled_flag,
    msib.mtl_transactions_enabled_flag, msib.reservable_type,
    msib.lot_control_code, msib.serial_number_control_code,
    msib.revision_qty_control_code, msib.location_control_code,
    msib.restrict_subinventories_code, msib.restrict_locators_code,
    msib.inventory_asset_flag, msib.costing_enabled_flag
FROM mtl_system_items_b msib, mtl_system_items_tl msit
WHERE
    msib.organization_id = :p_organization_id
    AND :p_language IS NOT NULL
    AND msib.inventory_item_id = msit.inventory_item_id(+)
    AND msib.organization_id = msit.organization_id(+)
    AND msit.language(+) = :p_language
    AND (:p_inventory_item_id IS NULL OR msib.inventory_item_id = :p_inventory_item_id)
    AND (:p_segment1 IS NULL OR msib.segment1 = :p_segment1)
    AND (:p_inventory_item_status_code IS NULL
         OR msib.inventory_item_status_code = :p_inventory_item_status_code)
ORDER BY msib.inventory_item_id;
