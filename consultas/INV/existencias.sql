/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : existencias.sql                                             ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Detalle y resumen de cantidades registradas.                ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorio NUMBER: p_organization_id (organización de inventario).          ║
║  Opcionales NUMBER: p_inventory_item_id, p_locator_id.                        ║
║  Opcionales texto: p_subinventory_code, p_lot_number.                         ║
║  Opcional NUMBER: p_is_consigned (1 consignado, 2 no consignado).             ║
║  No requiere idioma. Las existencias son actuales, sin fecha de corte.        ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- No equivale a disponible para reservar, prometer o despachar.
-- No reconstruye un saldo histórico ni incorpora transacciones pendientes.
-- Consulta 1: Una fila por registro de existencias (capa de recepción).
SELECT
    moqd.onhand_quantities_id,
    moqd.organization_id, moqd.inventory_item_id, moqd.subinventory_code,
    moqd.locator_id, moqd.revision, moqd.lot_number,
    moqd.cost_group_id, moqd.project_id, moqd.task_id,
    moqd.organization_type, moqd.owning_organization_id, moqd.owning_tp_type,
    moqd.planning_organization_id, moqd.planning_tp_type, moqd.is_consigned,
    moqd.lpn_id, moqd.status_id, moqd.secondary_uom_code,
    msib.primary_uom_code,
    moqd.primary_transaction_quantity,
    moqd.transaction_quantity, moqd.transaction_uom_code,
    moqd.secondary_transaction_quantity,
    moqd.date_received, moqd.orig_date_received,
    moqd.create_transaction_id, moqd.update_transaction_id
FROM mtl_onhand_quantities_detail moqd, mtl_system_items_b msib
WHERE
    moqd.organization_id = :p_organization_id
    AND (:p_inventory_item_id IS NULL OR moqd.inventory_item_id = :p_inventory_item_id)
    AND (:p_subinventory_code IS NULL OR moqd.subinventory_code = :p_subinventory_code)
    AND (:p_locator_id IS NULL OR moqd.locator_id = :p_locator_id)
    AND (:p_lot_number IS NULL OR moqd.lot_number = :p_lot_number)
    AND (:p_is_consigned IS NULL OR moqd.is_consigned = :p_is_consigned)
    AND moqd.inventory_item_id = msib.inventory_item_id(+)
    AND moqd.organization_id = msib.organization_id(+)
ORDER BY moqd.inventory_item_id, moqd.subinventory_code, moqd.onhand_quantities_id
/
-- Consulta 2: Suma capas manteniendo ubicación, propiedad, estado y unidades.
-- Los mismos filtros permiten comparar el resumen con el detalle.
-- No sumar TRANSACTION_QUANTITY de capas con diferentes unidades.
SELECT
    moqd.organization_id, moqd.inventory_item_id, moqd.subinventory_code,
    moqd.locator_id, moqd.revision, moqd.lot_number,
    moqd.cost_group_id, moqd.project_id, moqd.task_id,
    moqd.organization_type, moqd.owning_organization_id, moqd.owning_tp_type,
    moqd.planning_organization_id, moqd.planning_tp_type, moqd.is_consigned,
    moqd.lpn_id, moqd.status_id, moqd.secondary_uom_code,
    msib.primary_uom_code,
    COUNT(*) cantidad_registros,
    SUM(moqd.primary_transaction_quantity) existencia_primaria,
    SUM(moqd.secondary_transaction_quantity) existencia_secundaria
FROM mtl_onhand_quantities_detail moqd, mtl_system_items_b msib
WHERE
    moqd.organization_id = :p_organization_id
    AND (:p_inventory_item_id IS NULL OR moqd.inventory_item_id = :p_inventory_item_id)
    AND (:p_subinventory_code IS NULL OR moqd.subinventory_code = :p_subinventory_code)
    AND (:p_locator_id IS NULL OR moqd.locator_id = :p_locator_id)
    AND (:p_lot_number IS NULL OR moqd.lot_number = :p_lot_number)
    AND (:p_is_consigned IS NULL OR moqd.is_consigned = :p_is_consigned)
    AND moqd.inventory_item_id = msib.inventory_item_id(+)
    AND moqd.organization_id = msib.organization_id(+)
GROUP BY
    moqd.organization_id, moqd.inventory_item_id, moqd.subinventory_code,
    moqd.locator_id, moqd.revision, moqd.lot_number,
    moqd.cost_group_id, moqd.project_id, moqd.task_id,
    moqd.organization_type, moqd.owning_organization_id, moqd.owning_tp_type,
    moqd.planning_organization_id, moqd.planning_tp_type, moqd.is_consigned,
    moqd.lpn_id, moqd.status_id, moqd.secondary_uom_code,
    msib.primary_uom_code
ORDER BY moqd.inventory_item_id, moqd.subinventory_code, moqd.locator_id,
         moqd.lot_number, moqd.owning_organization_id;
