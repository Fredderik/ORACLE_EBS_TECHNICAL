/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pedidos_despachos.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Líneas de pedido y seguimiento de entregas WSH.             ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorio NUMBER: p_org_id (unidad operativa).                             ║
║  Opcionales NUMBER: p_header_id, p_order_number, p_order_type_id.             ║
║  Opcional NUMBER: p_sold_to_org_id (cuenta del cliente).                      ║
║  Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                   ║
║  Las fechas filtran ORDERED_DATE; ambos días incluidos.                       ║
║  Opcional NUMBER: p_line_id. No requiere idioma.                              ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Conserva líneas sin despacho; no representa recepción de devoluciones.
-- WSH pertenece a Shipping Execution; SOURCE_CODE = OE identifica origen OM.
-- No se mezclan unidades de medida de OM y WSH.
-- Se muestran todas las asignaciones, con ACTIVE_FLAG, incluso no activas.
-- Una línea puede dividirse en varios detalles/asignaciones: no sumar
-- las cantidades de OM repetidas ni repetir la cantidad de un detalle WSH.
SELECT
    ooha.org_id, ooha.header_id, ooha.order_number,
    oola.line_id, oola.line_number, oola.shipment_number,
    oola.ordered_item, oola.flow_status_code estado_linea,
    oola.ship_from_org_id almacen_linea_id,
    oola.order_quantity_uom, oola.ordered_quantity,
    oola.shipped_quantity cantidad_despachada_om,
    oola.actual_shipment_date,
    wdd.delivery_detail_id, wdd.source_code, wdd.organization_id almacen_wsh_id,
    wdd.released_status, wdd.container_flag,
    wdd.requested_quantity, wdd.requested_quantity_uom,
    wdd.shipped_quantity cantidad_despachada_wsh,
    wdd.delivered_quantity, wdd.date_requested, wdd.date_scheduled,
    wdd.subinventory, wdd.lot_number, wdd.tracking_number,
    wdd.oe_interfaced_flag, wdd.inv_interfaced_flag,
    wdd.split_from_delivery_detail_id,
    wda.delivery_assignment_id, wda.active_flag asignacion_activa,
    wda.parent_delivery_detail_id,
    wnd.delivery_id, wnd.name entrega, wnd.status_code estado_entrega
FROM oe_order_headers_all ooha, oe_order_lines_all oola,
     wsh_delivery_details wdd, wsh_delivery_assignments wda,
     wsh_new_deliveries wnd
WHERE
    ooha.org_id = :p_org_id
    AND (:p_header_id IS NULL OR ooha.header_id = :p_header_id)
    AND (:p_order_number IS NULL OR ooha.order_number = :p_order_number)
    AND (:p_order_type_id IS NULL OR ooha.order_type_id = :p_order_type_id)
    AND (:p_sold_to_org_id IS NULL OR ooha.sold_to_org_id = :p_sold_to_org_id)
    AND (:p_fecha_desde IS NULL
         OR ooha.ordered_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR ooha.ordered_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND ooha.header_id = oola.header_id
    AND ooha.org_id = oola.org_id
    AND (:p_line_id IS NULL OR oola.line_id = :p_line_id)
    AND oola.line_id = wdd.source_line_id(+)
    AND oola.header_id = wdd.source_header_id(+)
    AND oola.org_id = wdd.org_id(+)
    AND wdd.source_code(+) = 'OE'
    AND wdd.delivery_detail_id = wda.delivery_detail_id(+)
    AND wda.delivery_id = wnd.delivery_id(+)
ORDER BY ooha.order_number, oola.line_id, wdd.delivery_detail_id,
         wda.delivery_assignment_id;
