/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : requisiciones_ordenes_compra.sql                            ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Origen de órdenes de compra en requisiciones.               ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_org_id (NUMBER), unidad operativa de requisición.           ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_req_header_id (NUMBER), p_req_number (VARCHAR2).                       ║
║    * p_tipo_requisicion (VARCHAR2: PURCHASE o INTERNAL).                      ║
║    * p_fecha_desde, p_fecha_hasta (VARCHAR2; YYYY-MM-DD).                     ║
║    * p_po_header_id (NUMBER), p_po_number (VARCHAR2).                         ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; tablas base.                    ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin idioma ni organización obtenidos de la sesión.          ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    10/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por distribución de compra vinculada a una distribución de requisición.
-- El vínculo real es pda.req_distribution_id = prda.distribution_id.
-- No se enlazan los números comerciales ni las referencias de requisición en papel.
-- Solo muestra relaciones existentes; no incluye requisiciones sin compra asociada.
-- Las fechas y p_org_id filtran la cabecera de la requisición.
-- La organización de la compra se muestra por separado: no se infiere del origen.
-- Incluye documentos cancelados/cerrados; vínculo no significa compra vigente.
-- Conserva la liberación como opcional para órdenes que no la requieren.
-- No sumar cantidades/importes de requisición repetidos entre compras.
-- No calcula pendiente: unidades, monedas, cancelaciones y divisiones requieren
-- análisis específico. No reconstruye todo el árbol de líneas divididas.
-- No requiere idioma; los estados se muestran con sus códigos originales.

SELECT
    prha.org_id, prha.requisition_header_id, prha.segment1 numero_requisicion,
    prha.type_lookup_code tipo_requisicion, prha.creation_date,
    prha.authorization_status, prha.approved_date,
    prha.preparer_id preparador_id, prha.description,
    prha.cancel_flag cancelado_cabecera, prha.closed_code cierre_cabecera,
    prla.requisition_line_id, prla.line_num linea_requisicion,
    prla.parent_req_line_id, prla.item_id, prla.item_description,
    prla.unit_meas_lookup_code unidad_requisicion,
    prla.quantity cantidad_linea_req, prla.to_person_id solicitante_id,
    prla.cancel_flag cancelado_linea_req,
    prda.distribution_id distribucion_req_id,
    prda.distribution_num numero_distribucion_req,
    prda.req_line_quantity cantidad_distribucion_req,
    prda.req_line_amount importe_dist_req_funcional,
    prda.req_line_currency_amount, prla.currency_code moneda_requisicion,
    prda.code_combination_id cuenta_cargo_req_id,
    pha.org_id organizacion_compra, pha.po_header_id,
    pha.segment1 numero_orden, pha.type_lookup_code tipo_documento_compra,
    pha.creation_date fecha_creacion_compra,
    pha.authorization_status estado_compra,
    pha.cancel_flag cancelado_compra, pha.closed_code cierre_compra,
    pha.vendor_id, pha.vendor_site_id, pha.agent_id comprador_id,
    pha.currency_code moneda_compra,
    pla.po_line_id, pla.line_num linea_compra,
    pla.item_description descripcion_compra,
    pla.unit_meas_lookup_code unidad_compra, pla.unit_price precio_compra,
    pla.cancel_flag cancelado_linea_compra,
    plla.line_location_id, plla.shipment_num, plla.shipment_type,
    plla.need_by_date, plla.promised_date,
    plla.cancel_flag cancelado_envio, plla.closed_code cierre_envio,
    pra.po_release_id, pra.release_num, pra.release_date,
    pra.authorization_status estado_liberacion,
    pda.po_distribution_id, pda.distribution_num numero_distribucion_compra,
    pda.req_distribution_id,
    pda.quantity_ordered cantidad_ordenada_dist,
    pda.quantity_delivered cantidad_entregada_dist,
    pda.quantity_cancelled cantidad_cancelada_dist,
    pda.quantity_billed cantidad_facturada_dist,
    pda.amount_ordered importe_ordenado_dist,
    pda.amount_billed importe_facturado_dist,
    pda.code_combination_id cuenta_cargo_compra_id
FROM
    po_requisition_headers_all prha,
    po_requisition_lines_all prla,
    po_req_distributions_all prda,
    po_distributions_all pda,
    po_headers_all pha,
    po_lines_all pla,
    po_line_locations_all plla,
    po_releases_all pra
WHERE
    prha.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR prha.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR prha.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR prha.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR prha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR prha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND prha.requisition_header_id = prla.requisition_header_id
    AND prha.org_id = prla.org_id
    AND prla.requisition_line_id = prda.requisition_line_id
    AND prla.org_id = prda.org_id
    AND prda.distribution_id = pda.req_distribution_id
    AND pda.po_header_id = pha.po_header_id
    AND pda.org_id = pha.org_id
    AND pda.po_line_id = pla.po_line_id
    AND pda.po_header_id = pla.po_header_id
    AND pda.org_id = pla.org_id
    AND pda.line_location_id = plla.line_location_id
    AND pda.po_line_id = plla.po_line_id
    AND pda.po_header_id = plla.po_header_id
    AND pda.org_id = plla.org_id
    AND plla.po_release_id = pra.po_release_id(+)
    AND plla.po_header_id = pra.po_header_id(+)
    AND plla.org_id = pra.org_id(+)
    AND (:p_po_header_id IS NULL OR pha.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR pha.segment1 = :p_po_number)
ORDER BY prha.requisition_header_id, prla.line_num, prda.distribution_num,
         pha.po_header_id, pla.line_num, plla.shipment_num, pda.po_distribution_id;
