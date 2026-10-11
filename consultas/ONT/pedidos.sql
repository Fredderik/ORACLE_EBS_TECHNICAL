/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pedidos.sql                                                 ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Pedidos: cabeceras y líneas con cliente y tipo.             ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorio NUMBER: p_org_id (unidad operativa).                             ║
║  Opcionales NUMBER: p_header_id, p_order_number, p_order_type_id.             ║
║  Opcional NUMBER: p_sold_to_org_id (cuenta del cliente).                      ║
║  Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                   ║
║  Las fechas filtran ORDERED_DATE; ambos días incluidos.                       ║
║  Obligatorio texto: p_language (código EBS, por ejemplo US).                  ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- OM es Order Management; ONT es el nombre corto técnico de la aplicación.
-- Incluye pedidos abiertos, cerrados, cancelados y devoluciones.
-- SOLD_TO_ORG_ID es una cuenta de cliente, no la unidad operativa.
-- Las traducciones ausentes no eliminan pedidos ni líneas.
-- No se calcula un total: hay devoluciones, modelos, impuestos y cargos.
-- Consulta 1: Cabeceras, también pedidos sin líneas.
SELECT
    ooha.org_id, ooha.header_id, ooha.order_number, ooha.version_number,
    ooha.order_type_id, ooha.order_category_code,
    ooha.ordered_date, ooha.booked_date, ooha.request_date,
    ooha.flow_status_code estado_cabecera,
    ooha.booked_flag, ooha.open_flag abierto_cabecera,
    ooha.cancelled_flag cancelado_cabecera,
    ooha.transactional_curr_code moneda_pedido,
    ooha.sold_to_org_id cuenta_cliente_id,
    ooha.ship_to_org_id uso_sitio_envio_id,
    ooha.invoice_to_org_id uso_sitio_facturacion_id,
    ooha.ship_from_org_id almacen_cabecera_id,
    ooha.cust_po_number, ooha.order_source_id, ooha.orig_sys_document_ref,
    ooha.price_list_id, ooha.payment_term_id, ooha.salesrep_id,
    ottt.name tipo_pedido, hca.account_number numero_cuenta_cliente,
    hp.party_name nombre_cliente, oos.name origen_pedido
FROM oe_order_headers_all ooha, oe_transaction_types_tl ottt,
     hz_cust_accounts hca, hz_parties hp, oe_order_sources oos
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
    AND :p_language IS NOT NULL
    AND ooha.order_type_id = ottt.transaction_type_id(+)
    AND ottt.language(+) = :p_language
    AND ooha.sold_to_org_id = hca.cust_account_id(+)
    AND hca.party_id = hp.party_id(+)
    AND ooha.order_source_id = oos.order_source_id(+)
ORDER BY ooha.order_number, ooha.header_id
/
-- Consulta 2: Cabeceras y líneas; conserva cabeceras sin líneas.
-- El slash ejecuta la primera consulta sin punto y coma previo.
SELECT
    ooha.org_id, ooha.header_id, ooha.order_number, ooha.version_number,
    ooha.order_type_id, ooha.order_category_code,
    ooha.ordered_date, ooha.booked_date, ooha.request_date,
    ooha.flow_status_code estado_cabecera,
    ooha.booked_flag, ooha.open_flag abierto_cabecera,
    ooha.cancelled_flag cancelado_cabecera,
    ooha.transactional_curr_code moneda_pedido,
    ooha.sold_to_org_id cuenta_cliente_id,
    ooha.ship_to_org_id uso_sitio_envio_id,
    ooha.invoice_to_org_id uso_sitio_facturacion_id,
    ooha.ship_from_org_id almacen_cabecera_id,
    ooha.cust_po_number, ooha.order_source_id, ooha.orig_sys_document_ref,
    ooha.price_list_id, ooha.payment_term_id, ooha.salesrep_id,
    ottt.name tipo_pedido, hca.account_number numero_cuenta_cliente,
    hp.party_name nombre_cliente, oos.name origen_pedido,
    oola.line_id, oola.line_number, oola.shipment_number,
    oola.line_type_id, oola.line_category_code, oola.item_type_code,
    oola.inventory_item_id, oola.ordered_item,
    oola.ship_from_org_id almacen_linea_id,
    oola.order_quantity_uom, oola.ordered_quantity,
    oola.cancelled_quantity, oola.shipped_quantity,
    oola.fulfilled_quantity, oola.invoiced_quantity,
    oola.unit_list_price, oola.unit_selling_price,
    oola.flow_status_code estado_linea,
    oola.open_flag abierto_linea, oola.cancelled_flag cancelado_linea,
    oola.shippable_flag, oola.schedule_ship_date, oola.actual_shipment_date,
    oola.invoice_interface_status_code,
    oola.link_to_line_id, oola.top_model_line_id, oola.split_from_line_id,
    ottt_linea.name tipo_linea
FROM oe_order_headers_all ooha, oe_transaction_types_tl ottt,
     hz_cust_accounts hca, hz_parties hp, oe_order_sources oos,
     oe_order_lines_all oola, oe_transaction_types_tl ottt_linea
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
    AND :p_language IS NOT NULL
    AND ooha.order_type_id = ottt.transaction_type_id(+)
    AND ottt.language(+) = :p_language
    AND ooha.sold_to_org_id = hca.cust_account_id(+)
    AND hca.party_id = hp.party_id(+)
    AND ooha.order_source_id = oos.order_source_id(+)
    AND ooha.header_id = oola.header_id(+)
    AND ooha.org_id = oola.org_id(+)
    AND oola.line_type_id = ottt_linea.transaction_type_id(+)
    AND ottt_linea.language(+) = :p_language
ORDER BY ooha.order_number, ooha.header_id, oola.line_number,
         oola.shipment_number, oola.line_id;
