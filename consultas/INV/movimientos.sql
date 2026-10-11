/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : movimientos.sql                                             ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Transacciones de material y detalle de lotes.               ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorio NUMBER: p_organization_id.                                       ║
║  Opcionales NUMBER: p_inventory_item_id, p_transaction_id,                    ║
║  p_transaction_type_id. Opcional texto: p_subinventory_code.                  ║
║  Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                   ║
║  Fechas de TRANSACTION_DATE, días inclusivos. Sin parámetro de idioma.        ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- El tipo conserva el nombre almacenado en MTL_TRANSACTION_TYPES.
-- Mantener el signo y la unidad; no sumar artículos/unidades distintos.
-- TRANSACTION_SOURCE_ID se interpreta según TRANSACTION_SOURCE_TYPE_ID.
-- Este detalle no demuestra contabilización GL ni constituye valoración.
-- Consulta 1: Una fila por transacción.
SELECT
    mmt.organization_id, mmt.inventory_item_id, mmt.transaction_id,
    mmt.transaction_date, mmt.transaction_type_id,
    mtt.transaction_type_name nombre_tipo_registrado,
    mmt.transaction_action_id, mmt.transaction_source_type_id,
    mmt.transaction_source_id, mmt.transaction_source_name,
    mmt.transaction_quantity, mmt.transaction_uom,
    mmt.primary_quantity, msib.primary_uom_code,
    mmt.subinventory_code, mmt.locator_id, mmt.revision,
    mmt.transaction_reference, mmt.reason_id,
    mmt.transfer_transaction_id, mmt.transfer_organization_id,
    mmt.transfer_subinventory, mmt.transfer_locator_id,
    mmt.rcv_transaction_id, mmt.trx_source_line_id,
    mmt.costed_flag, mmt.distribution_account_id
FROM mtl_material_transactions mmt, mtl_transaction_types mtt,
     mtl_system_items_b msib
WHERE
    mmt.organization_id = :p_organization_id
    AND (:p_inventory_item_id IS NULL OR mmt.inventory_item_id = :p_inventory_item_id)
    AND (:p_transaction_id IS NULL OR mmt.transaction_id = :p_transaction_id)
    AND (:p_transaction_type_id IS NULL OR mmt.transaction_type_id = :p_transaction_type_id)
    AND (:p_subinventory_code IS NULL OR mmt.subinventory_code = :p_subinventory_code)
    AND (:p_fecha_desde IS NULL
         OR mmt.transaction_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR mmt.transaction_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND mmt.transaction_type_id = mtt.transaction_type_id(+)
    AND mmt.inventory_item_id = msib.inventory_item_id(+)
    AND mmt.organization_id = msib.organization_id(+)
ORDER BY mmt.transaction_date, mmt.transaction_id
/
-- Consulta 2: Transacción y lotes; conserva movimientos sin control de lote.
-- Los importes/cantidades de MMT se repiten por lote: no sumarlos aquí.
-- SERIAL_TRANSACTION_ID es una referencia, no el número de serie.
SELECT
    mmt.organization_id, mmt.inventory_item_id, mmt.transaction_id,
    mmt.transaction_date, mmt.transaction_type_id,
    mtt.transaction_type_name nombre_tipo_registrado,
    mmt.transaction_action_id, mmt.transaction_source_type_id,
    mmt.transaction_source_id, mmt.transaction_source_name,
    mmt.transaction_quantity, mmt.transaction_uom,
    mmt.primary_quantity, msib.primary_uom_code,
    mmt.subinventory_code, mmt.locator_id, mmt.revision,
    mmt.transaction_reference, mmt.reason_id,
    mmt.transfer_transaction_id, mmt.transfer_organization_id,
    mmt.transfer_subinventory, mmt.transfer_locator_id,
    mmt.rcv_transaction_id, mmt.trx_source_line_id,
    mmt.costed_flag, mmt.distribution_account_id,
    mtln.lot_number, mtln.transaction_quantity cantidad_lote_transaccion,
    mtln.primary_quantity cantidad_lote_primaria,
    mtln.serial_transaction_id
FROM mtl_material_transactions mmt, mtl_transaction_types mtt,
     mtl_system_items_b msib, mtl_transaction_lot_numbers mtln
WHERE
    mmt.organization_id = :p_organization_id
    AND (:p_inventory_item_id IS NULL OR mmt.inventory_item_id = :p_inventory_item_id)
    AND (:p_transaction_id IS NULL OR mmt.transaction_id = :p_transaction_id)
    AND (:p_transaction_type_id IS NULL OR mmt.transaction_type_id = :p_transaction_type_id)
    AND (:p_subinventory_code IS NULL OR mmt.subinventory_code = :p_subinventory_code)
    AND (:p_fecha_desde IS NULL
         OR mmt.transaction_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR mmt.transaction_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND mmt.transaction_type_id = mtt.transaction_type_id(+)
    AND mmt.inventory_item_id = msib.inventory_item_id(+)
    AND mmt.organization_id = msib.organization_id(+)
    AND mmt.transaction_id = mtln.transaction_id(+)
    AND mmt.organization_id = mtln.organization_id(+)
    AND mmt.inventory_item_id = mtln.inventory_item_id(+)
ORDER BY mmt.transaction_date, mmt.transaction_id, mtln.lot_number;
