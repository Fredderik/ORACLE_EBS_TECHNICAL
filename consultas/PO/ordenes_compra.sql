/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : ordenes_compra.sql                                          ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
    h.org_id, h.po_header_id, h.segment1 numero_documento,
    h.type_lookup_code, h.creation_date, h.revision_num,
    h.authorization_status, h.approved_flag, h.approved_date,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    h.vendor_id, s.segment1 proveedor_numero, s.vendor_name,
    h.vendor_site_id, ss.vendor_site_code,
    h.agent_id comprador_id, h.currency_code,
    h.rate_type, h.rate_date, h.rate,
    h.terms_id, t.name condiciones_pago,
    h.ship_to_location_id, h.bill_to_location_id,
    h.comments
FROM
    po_headers_all h,
    ap_suppliers s,
    ap_supplier_sites_all ss,
    ap_terms_tl t
WHERE
    h.org_id = :p_org_id
    AND h.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR h.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR h.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR h.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY h.po_header_id
/
-- Consulta 2: Cabecera y líneas.
SELECT
    h.org_id, h.po_header_id, h.segment1 numero_documento,
    h.type_lookup_code, h.creation_date, h.revision_num,
    h.authorization_status, h.approved_flag, h.approved_date,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    h.vendor_id, s.segment1 proveedor_numero, s.vendor_name,
    h.vendor_site_id, ss.vendor_site_code,
    h.agent_id comprador_id, h.currency_code,
    h.rate_type, h.rate_date, h.rate,
    h.terms_id, t.name condiciones_pago,
    h.ship_to_location_id, h.bill_to_location_id,
    h.comments,
    l.po_line_id, l.line_num, l.line_type_id,
    lt.line_type tipo_linea, l.item_id, l.item_description,
    l.category_id, l.unit_meas_lookup_code,
    l.quantity cantidad_linea, l.unit_price precio_linea,
    l.amount importe_linea_registrado,
    l.cancel_flag cancelado_linea, l.closed_code cierre_linea
FROM
    po_headers_all h,
    ap_suppliers s,
    ap_supplier_sites_all ss,
    ap_terms_tl t,
    po_lines_all l,
    po_line_types_tl lt
WHERE
    h.org_id = :p_org_id
    AND h.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR h.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR h.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR h.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.po_header_id = l.po_header_id(+)
    AND h.org_id = l.org_id(+)
    AND l.line_type_id = lt.line_type_id(+)
    AND lt.language(+) = :p_language
ORDER BY h.po_header_id, l.line_num, l.po_line_id
/
-- Consulta 3: Cabecera, líneas, envíos y distribuciones.
SELECT
    h.org_id, h.po_header_id, h.segment1 numero_documento,
    h.type_lookup_code, h.creation_date, h.revision_num,
    h.authorization_status, h.approved_flag, h.approved_date,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    h.vendor_id, s.segment1 proveedor_numero, s.vendor_name,
    h.vendor_site_id, ss.vendor_site_code,
    h.agent_id comprador_id, h.currency_code,
    h.rate_type, h.rate_date, h.rate,
    h.terms_id, t.name condiciones_pago,
    h.ship_to_location_id, h.bill_to_location_id,
    h.comments,
    l.po_line_id, l.line_num, l.line_type_id,
    lt.line_type tipo_linea, l.item_id, l.item_description,
    l.category_id, l.unit_meas_lookup_code,
    l.quantity cantidad_linea, l.unit_price precio_linea,
    l.amount importe_linea_registrado,
    l.cancel_flag cancelado_linea, l.closed_code cierre_linea,
    sh.line_location_id, sh.shipment_num, sh.shipment_type,
    sh.po_release_id, rel.release_num, rel.release_date,
    rel.authorization_status estado_liberacion,
    sh.need_by_date, sh.promised_date,
    sh.ship_to_organization_id, sh.ship_to_location_id destino_envio_id,
    sh.quantity cantidad_envio, sh.quantity_received,
    sh.quantity_accepted, sh.quantity_rejected,
    sh.quantity_billed, sh.quantity_cancelled,
    sh.amount importe_envio_registrado, sh.amount_billed,
    sh.cancel_flag cancelado_envio, sh.closed_code cierre_envio,
    sh.receipt_required_flag, sh.inspection_required_flag,
    sh.match_option,
    d.po_distribution_id, d.distribution_num,
    d.destination_type_code, d.destination_organization_id,
    d.destination_subinventory, d.deliver_to_person_id,
    d.deliver_to_location_id, d.req_distribution_id,
    d.code_combination_id cuenta_cargo_id,
    d.accrual_account_id, d.variance_account_id, d.budget_account_id,
    d.quantity_ordered cantidad_distribucion,
    d.quantity_delivered, d.quantity_billed facturado_distribucion,
    d.amount_ordered importe_distribucion,
    d.amount_billed importe_facturado_dist,
    d.accrued_flag, d.encumbered_flag,
    d.project_id, d.task_id
FROM
    po_headers_all h,
    ap_suppliers s,
    ap_supplier_sites_all ss,
    ap_terms_tl t,
    po_lines_all l,
    po_line_types_tl lt,
    po_line_locations_all sh,
    po_releases_all rel,
    po_distributions_all d
WHERE
    h.org_id = :p_org_id
    AND h.type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
    AND (:p_po_header_id IS NULL OR h.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR h.segment1 = :p_po_number)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_type_lookup_code IS NULL OR h.type_lookup_code = :p_type_lookup_code)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.po_header_id = l.po_header_id(+)
    AND h.org_id = l.org_id(+)
    AND l.line_type_id = lt.line_type_id(+)
    AND lt.language(+) = :p_language
    AND l.po_header_id = sh.po_header_id(+)
    AND l.po_line_id = sh.po_line_id(+)
    AND l.org_id = sh.org_id(+)
    AND sh.po_release_id = rel.po_release_id(+)
    AND sh.po_header_id = rel.po_header_id(+)
    AND sh.org_id = rel.org_id(+)
    AND sh.line_location_id = d.line_location_id(+)
    AND sh.po_line_id = d.po_line_id(+)
    AND sh.po_header_id = d.po_header_id(+)
    AND sh.org_id = d.org_id(+)
ORDER BY h.po_header_id, l.line_num, l.po_line_id, rel.release_num, sh.shipment_num, sh.line_location_id, d.distribution_num, d.po_distribution_id;
