/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : configuracion_inv.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Organizaciones, subinventarios y localizadores.             ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  p_organization_id (NUMBER): opcional en consulta 1;                          ║
║  obligatorio en consultas 2 y 3.                                              ║
║  p_subinventory_code (texto): opcional en consultas 2 y 3.                    ║
║  p_locator_id (NUMBER): opcional en consulta 3. No requiere idioma.           ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Organizaciones de inventario; NULL permite descubrir sus IDs.
-- ORGANIZATION_ID no debe confundirse con el ORG_ID de una unidad operativa.
SELECT
    mp.organization_id, mp.organization_code, mp.master_organization_id,
    mp.cost_organization_id, mp.primary_cost_method,
    mp.stock_locator_control_code, mp.negative_inv_receipt_code,
    mp.lot_number_generation, mp.serial_number_generation,
    mp.wms_enabled_flag, mp.process_enabled_flag,
    mp.material_account, mp.expense_account
FROM mtl_parameters mp
WHERE (:p_organization_id IS NULL OR mp.organization_id = :p_organization_id)
ORDER BY mp.organization_code, mp.organization_id
/
-- Consulta 2: Subinventarios de una organización, incluidos los deshabilitados.
SELECT
    msi.organization_id, msi.secondary_inventory_name, msi.description,
    msi.disable_date, msi.subinventory_type, msi.status_id,
    msi.quantity_tracked, msi.asset_inventory,
    msi.reservable_type, msi.availability_type, msi.inventory_atp_code,
    msi.locator_type, msi.default_cost_group_id,
    msi.material_account, msi.expense_account
FROM mtl_secondary_inventories msi
WHERE
    msi.organization_id = :p_organization_id
    AND (:p_subinventory_code IS NULL
         OR msi.secondary_inventory_name = :p_subinventory_code)
ORDER BY msi.secondary_inventory_name
/
-- Consulta 3: Localizadores; no se presupone la estructura del flexfield MTLL.
SELECT
    mil.organization_id, mil.inventory_location_id, mil.subinventory_code,
    mil.description, mil.disable_date, mil.inventory_location_type,
    mil.segment1, mil.segment2, mil.segment3, mil.segment4,
    mil.segment5, mil.segment6, mil.segment7, mil.segment8,
    mil.segment9, mil.segment10, mil.segment11, mil.segment12,
    mil.segment13, mil.segment14, mil.segment15, mil.segment16,
    mil.segment17, mil.segment18, mil.segment19, mil.segment20
FROM mtl_item_locations mil
WHERE
    mil.organization_id = :p_organization_id
    AND (:p_subinventory_code IS NULL OR mil.subinventory_code = :p_subinventory_code)
    AND (:p_locator_id IS NULL OR mil.inventory_location_id = :p_locator_id)
ORDER BY mil.subinventory_code, mil.inventory_location_id;
