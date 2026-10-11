/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pedidos_facturacion.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Líneas OM y transacciones importadas a AR.                  ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Obligatorio NUMBER: p_org_id (unidad operativa).                             ║
║  Opcionales NUMBER: p_header_id, p_order_number, p_order_type_id.             ║
║  Opcional NUMBER: p_sold_to_org_id (cuenta del cliente).                      ║
║  Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                   ║
║  Las fechas filtran ORDERED_DATE; ambos días incluidos.                       ║
║  Opcional NUMBER: p_line_id. No requiere idioma.                              ║
║  Obligatorio texto: p_interface_line_context (ejemplo ORDER ENTRY).           ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Relación estándar: INTERFACE_LINE_ATTRIBUTE6 contiene LINE_ID de OM.
-- El contexto se digita; no se obtiene del perfil ni de la sesión.
-- Convertir el identificador OM a texto evita errores con atributos no numéricos.
-- Solo líneas AR de tipo LINE. No incluye impuestos, fletes ni saldos pendientes.
-- Una línea OM puede originar varias líneas AR; no repetir importes de OM.
-- Sin vínculo no equivale a error: puede estar pendiente o no ser facturable,
-- usar otra organización/contexto o una integración con un mapeo diferente.
SELECT
    ooha.org_id, ooha.header_id, ooha.order_number,
    ooha.transactional_curr_code moneda_pedido,
    oola.line_id, oola.line_number, oola.shipment_number,
    oola.ordered_item, oola.line_category_code,
    oola.flow_status_code estado_linea,
    oola.invoice_interface_status_code, oola.invoiced_quantity,
    rctla.customer_trx_line_id, rctla.line_number linea_ar,
    rctla.interface_line_context, rctla.interface_line_attribute6,
    rctla.sales_order, rctla.sales_order_line,
    rctla.quantity_invoiced, rctla.quantity_credited,
    rctla.unit_selling_price precio_unitario_ar,
    rctla.extended_amount importe_linea_ar,
    rcta.customer_trx_id, rcta.trx_number, rcta.trx_date,
    rcta.invoice_currency_code moneda_ar,
    rcta.cust_trx_type_id, rcta.complete_flag,
    CASE WHEN rctla.customer_trx_line_id IS NULL THEN 'SIN VINCULO AR'
         ELSE 'CON VINCULO AR' END diagnostico_vinculo
FROM oe_order_headers_all ooha, oe_order_lines_all oola,
     ra_customer_trx_lines_all rctla, ra_customer_trx_all rcta
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
    AND :p_interface_line_context IS NOT NULL
    AND TO_CHAR(oola.line_id, 'TM9') = rctla.interface_line_attribute6(+)
    AND oola.org_id = rctla.org_id(+)
    AND rctla.interface_line_context(+) = :p_interface_line_context
    AND rctla.line_type(+) = 'LINE'
    AND rctla.customer_trx_id = rcta.customer_trx_id(+)
    AND rctla.org_id = rcta.org_id(+)
ORDER BY ooha.order_number, oola.line_id, rcta.customer_trx_id,
         rctla.customer_trx_line_id;
