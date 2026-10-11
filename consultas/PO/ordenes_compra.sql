/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : ordenes_compra.sql                                          ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Órdenes, acuerdos, envíos y distribuciones.                 ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorios: p_org_id (NUMBER), p_language (código EBS, ej. US).          ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_po_header_id, p_vendor_id (NUMBER); p_po_number (VARCHAR2).            ║
║    * p_type_lookup_code (STANDARD, PLANNED, BLANKET o CONTRACT).              ║
║    * p_fecha_desde, p_fecha_hasta (VARCHAR2; YYYY-MM-DD; días inclusivos).    ║
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

-- Se consulta la revisión actual, incluyendo documentos cerrados/cancelados.
-- Los tres resultados aplican los mismos filtros de cabecera.
-- Las fechas filtran CREATION_DATE del documento, no las de la liberación.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.
-- Las cantidades/importes de línea o envío se repiten al bajar de nivel.
-- AMOUNT se muestra tal como está registrado; puede ser NULL en compras
-- basadas en cantidad. No se infiere un total universal como cantidad*precio.

-- Consulta 1: Cabecera de orden o acuerdo.
SELECT
    pha.org_id, pha.po_header_id, pha.segment1 numero_documento,
    pha.type_lookup_code, pha.creation_date, pha.revision_num,
    pha.authorization_status, pha.approved_flag, pha.approved_date,
    pha.cancel_flag cancelado_cabecera, pha.closed_code cierre_cabecera,
    pha.vendor_id, aps.segment1 proveedor_numero, aps.vendor_name,
    pha.vendor_site_id, assa.vendor_site_code,
    pha.agent_id comprador_id, pha.currency_code,
    pha.rate_type, pha.rate_date, pha.rate,
    pha.terms_id, att.name condiciones_pago,
    pha.ship_to_location_id, pha.bill_to_location_id,
    pha.comments
FROM
    po_headers_all pha,
    ap_suppliers aps,
    ap_supplier_sites_all assa,
    ap_terms_tl att
WHERE
    pha.org_id = :p_org_id
    AND pha.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR pha.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR pha.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR pha.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR pha.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR pha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR pha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND pha.vendor_id = aps.vendor_id(+)
    AND pha.vendor_site_id = assa.vendor_site_id(+)
    AND pha.vendor_id = assa.vendor_id(+)
    AND pha.org_id = assa.org_id(+)
    AND pha.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
ORDER BY pha.po_header_id
/
-- Consulta 2: Cabecera y líneas.
SELECT
    pha.org_id, pha.po_header_id, pha.segment1 numero_documento,
    pha.type_lookup_code, pha.creation_date, pha.revision_num,
    pha.authorization_status, pha.approved_flag, pha.approved_date,
    pha.cancel_flag cancelado_cabecera, pha.closed_code cierre_cabecera,
    pha.vendor_id, aps.segment1 proveedor_numero, aps.vendor_name,
    pha.vendor_site_id, assa.vendor_site_code,
    pha.agent_id comprador_id, pha.currency_code,
    pha.rate_type, pha.rate_date, pha.rate,
    pha.terms_id, att.name condiciones_pago,
    pha.ship_to_location_id, pha.bill_to_location_id,
    pha.comments,
    pla.po_line_id, pla.line_num, pla.line_type_id,
    pltt.line_type tipo_linea, pla.item_id, pla.item_description,
    pla.category_id, pla.unit_meas_lookup_code,
    pla.quantity cantidad_linea, pla.unit_price precio_linea,
    pla.amount importe_linea_registrado,
    pla.cancel_flag cancelado_linea, pla.closed_code cierre_linea
FROM
    po_headers_all pha,
    ap_suppliers aps,
    ap_supplier_sites_all assa,
    ap_terms_tl att,
    po_lines_all pla,
    po_line_types_tl pltt
WHERE
    pha.org_id = :p_org_id
    AND pha.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR pha.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR pha.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR pha.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR pha.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR pha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR pha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND pha.vendor_id = aps.vendor_id(+)
    AND pha.vendor_site_id = assa.vendor_site_id(+)
    AND pha.vendor_id = assa.vendor_id(+)
    AND pha.org_id = assa.org_id(+)
    AND pha.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
    AND pha.po_header_id = pla.po_header_id(+)
    AND pha.org_id = pla.org_id(+)
    AND pla.line_type_id = pltt.line_type_id(+)
    AND pltt.language(+) = :p_language
ORDER BY pha.po_header_id, pla.line_num, pla.po_line_id
/
-- Consulta 3: Cabecera, líneas, envíos y distribuciones.
SELECT
    pha.org_id, pha.po_header_id, pha.segment1 numero_documento,
    pha.type_lookup_code, pha.creation_date, pha.revision_num,
    pha.authorization_status, pha.approved_flag, pha.approved_date,
    pha.cancel_flag cancelado_cabecera, pha.closed_code cierre_cabecera,
    pha.vendor_id, aps.segment1 proveedor_numero, aps.vendor_name,
    pha.vendor_site_id, assa.vendor_site_code,
    pha.agent_id comprador_id, pha.currency_code,
    pha.rate_type, pha.rate_date, pha.rate,
    pha.terms_id, att.name condiciones_pago,
    pha.ship_to_location_id, pha.bill_to_location_id,
    pha.comments,
    pla.po_line_id, pla.line_num, pla.line_type_id,
    pltt.line_type tipo_linea, pla.item_id, pla.item_description,
    pla.category_id, pla.unit_meas_lookup_code,
    pla.quantity cantidad_linea, pla.unit_price precio_linea,
    pla.amount importe_linea_registrado,
    pla.cancel_flag cancelado_linea, pla.closed_code cierre_linea,
    plla.line_location_id, plla.shipment_num, plla.shipment_type,
    plla.po_release_id, pra.release_num, pra.release_date,
    pra.authorization_status estado_liberacion,
    plla.need_by_date, plla.promised_date,
    plla.ship_to_organization_id, plla.ship_to_location_id destino_envio_id,
    plla.quantity cantidad_envio, plla.quantity_received,
    plla.quantity_accepted, plla.quantity_rejected,
    plla.quantity_billed, plla.quantity_cancelled,
    plla.amount importe_envio_registrado, plla.amount_billed,
    plla.cancel_flag cancelado_envio, plla.closed_code cierre_envio,
    plla.receipt_required_flag, plla.inspection_required_flag,
    plla.match_option,
    pda.po_distribution_id, pda.distribution_num,
    pda.destination_type_code, pda.destination_organization_id,
    pda.destination_subinventory, pda.deliver_to_person_id,
    pda.deliver_to_location_id, pda.req_distribution_id,
    pda.code_combination_id cuenta_cargo_id,
    pda.accrual_account_id, pda.variance_account_id, pda.budget_account_id,
    pda.quantity_ordered cantidad_distribucion,
    pda.quantity_delivered, pda.quantity_billed facturado_distribucion,
    pda.amount_ordered importe_distribucion,
    pda.amount_billed importe_facturado_dist,
    pda.accrued_flag, pda.encumbered_flag,
    pda.project_id, pda.task_id
FROM
    po_headers_all pha,
    ap_suppliers aps,
    ap_supplier_sites_all assa,
    ap_terms_tl att,
    po_lines_all pla,
    po_line_types_tl pltt,
    po_line_locations_all plla,
    po_releases_all pra,
    po_distributions_all pda
WHERE
    pha.org_id = :p_org_id
    AND pha.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR pha.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR pha.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR pha.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR pha.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR pha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR pha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND pha.vendor_id = aps.vendor_id(+)
    AND pha.vendor_site_id = assa.vendor_site_id(+)
    AND pha.vendor_id = assa.vendor_id(+)
    AND pha.org_id = assa.org_id(+)
    AND pha.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
    AND pha.po_header_id = pla.po_header_id(+)
    AND pha.org_id = pla.org_id(+)
    AND pla.line_type_id = pltt.line_type_id(+)
    AND pltt.language(+) = :p_language
    AND pla.po_header_id = plla.po_header_id(+)
    AND pla.po_line_id = plla.po_line_id(+)
    AND pla.org_id = plla.org_id(+)
    AND plla.po_release_id = pra.po_release_id(+)
    AND plla.po_header_id = pra.po_header_id(+)
    AND plla.org_id = pra.org_id(+)
    AND plla.line_location_id = pda.line_location_id(+)
    AND plla.po_line_id = pda.po_line_id(+)
    AND plla.po_header_id = pda.po_header_id(+)
    AND plla.org_id = pda.org_id(+)
ORDER BY pha.po_header_id, pla.line_num, pla.po_line_id, pra.release_num, plla.shipment_num, plla.line_location_id, pda.distribution_num, pda.po_distribution_id;
