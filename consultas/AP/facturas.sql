/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : facturas.sql                                                ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Facturas: cabecera, líneas y distribuciones.                ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorios: p_org_id (NUMBER), p_language (código EBS, ej. US).          ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_invoice_id (NUMBER), p_invoice_num (VARCHAR2), p_vendor_id (NUMBER).   ║
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

-- Los tres resultados utilizan exactamente los mismos filtros de cabecera.
-- Se incluyen facturas canceladas y líneas descartadas o revertidas.
-- Las uniones externas conservan cabeceras sin líneas y líneas sin distribución.
-- No sumar importe_factura en el detalle, ni importe_linea por distribución:
-- ambos importes se repiten al descender de nivel.
-- Los códigos de aprobación/contabilización se muestran sin reinterpretarlos.
-- Cada / ejecuta el SELECT anterior: no colocar ; antes del separador.

-- Consulta 1: Cabecera (una fila por factura).
SELECT
    h.org_id,
    h.set_of_books_id,
    h.invoice_id,
    h.invoice_num,
    h.invoice_type_lookup_code,
    h.invoice_date,
    h.gl_date,
    h.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name proveedor_nombre,
    h.vendor_site_id,
    ss.vendor_site_code sitio_proveedor,
    h.invoice_currency_code,
    h.payment_currency_code,
    h.invoice_amount importe_factura,
    h.base_amount importe_base_factura,
    h.amount_paid importe_pagado,
    h.payment_status_flag,
    h.wfapproval_status,
    h.cancelled_date,
    h.source,
    h.description descripcion_factura,
    h.terms_id,
    t.name condiciones_pago,
    h.terms_date,
    h.accts_pay_code_combination_id cuenta_pasivo_id
FROM
    ap_invoices_all       h,
    ap_suppliers          s,
    ap_supplier_sites_all ss,
    ap_terms_tl           t
WHERE
        h.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR h.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR h.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR h.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY h.invoice_id
/
-- Consulta 2: Cabecera y líneas (una fila por línea, si existe).
SELECT
    h.org_id,
    h.set_of_books_id,
    h.invoice_id,
    h.invoice_num,
    h.invoice_type_lookup_code,
    h.invoice_date,
    h.gl_date,
    h.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name proveedor_nombre,
    h.vendor_site_id,
    ss.vendor_site_code sitio_proveedor,
    h.invoice_currency_code,
    h.payment_currency_code,
    h.invoice_amount importe_factura,
    h.base_amount importe_base_factura,
    h.amount_paid importe_pagado,
    h.payment_status_flag,
    h.wfapproval_status,
    h.cancelled_date,
    h.source,
    h.description descripcion_factura,
    h.terms_id,
    t.name condiciones_pago,
    h.terms_date,
    h.accts_pay_code_combination_id cuenta_pasivo_id,
    l.line_number numero_linea,
    l.line_type_lookup_code tipo_linea,
    l.description descripcion_linea,
    l.amount importe_linea,
    l.base_amount importe_base_linea,
    l.accounting_date fecha_contable_linea,
    l.quantity_invoiced,
    l.unit_price,
    l.unit_meas_lookup_code,
    l.discarded_flag,
    l.cancelled_flag,
    l.po_header_id,
    l.po_line_id,
    l.po_line_location_id,
    l.po_distribution_id,
    l.rcv_transaction_id
FROM
    ap_invoices_all       h,
    ap_suppliers          s,
    ap_supplier_sites_all ss,
    ap_terms_tl           t,
    ap_invoice_lines_all l
WHERE
        h.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR h.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR h.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR h.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.invoice_id = l.invoice_id(+)
    AND h.org_id = l.org_id(+)
ORDER BY h.invoice_id, l.line_number
/
-- Consulta 3: Cabecera, líneas y distribuciones (una fila por distribución, si existe).
SELECT
    h.org_id,
    h.set_of_books_id,
    h.invoice_id,
    h.invoice_num,
    h.invoice_type_lookup_code,
    h.invoice_date,
    h.gl_date,
    h.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name proveedor_nombre,
    h.vendor_site_id,
    ss.vendor_site_code sitio_proveedor,
    h.invoice_currency_code,
    h.payment_currency_code,
    h.invoice_amount importe_factura,
    h.base_amount importe_base_factura,
    h.amount_paid importe_pagado,
    h.payment_status_flag,
    h.wfapproval_status,
    h.cancelled_date,
    h.source,
    h.description descripcion_factura,
    h.terms_id,
    t.name condiciones_pago,
    h.terms_date,
    h.accts_pay_code_combination_id cuenta_pasivo_id,
    l.line_number numero_linea,
    l.line_type_lookup_code tipo_linea,
    l.description descripcion_linea,
    l.amount importe_linea,
    l.base_amount importe_base_linea,
    l.accounting_date fecha_contable_linea,
    l.quantity_invoiced,
    l.unit_price,
    l.unit_meas_lookup_code,
    l.discarded_flag,
    l.cancelled_flag,
    l.po_header_id,
    l.po_line_id,
    l.po_line_location_id,
    l.po_distribution_id,
    l.rcv_transaction_id,
    d.invoice_distribution_id,
    d.distribution_line_number numero_distribucion,
    d.line_type_lookup_code tipo_distribucion,
    d.description descripcion_distribucion,
    d.amount importe_distribucion,
    d.base_amount importe_base_distribucion,
    d.accounting_date fecha_contable_distribucion,
    d.period_name,
    d.dist_code_combination_id cuenta_distribucion_id,
    d.posted_flag,
    d.match_status_flag,
    d.reversal_flag,
    d.parent_reversal_id,
    d.po_distribution_id oc_distribucion_id,
    d.project_id,
    d.task_id,
    d.expenditure_type
FROM
    ap_invoices_all       h,
    ap_suppliers          s,
    ap_supplier_sites_all ss,
    ap_terms_tl           t,
    ap_invoice_lines_all l,
    ap_invoice_distributions_all d
WHERE
        h.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR h.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR h.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR h.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR h.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.vendor_id = s.vendor_id(+)
    AND h.vendor_site_id = ss.vendor_site_id(+)
    AND h.vendor_id = ss.vendor_id(+)
    AND h.org_id = ss.org_id(+)
    AND h.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.invoice_id = l.invoice_id(+)
    AND h.org_id = l.org_id(+)
    AND l.invoice_id = d.invoice_id(+)
    AND l.line_number = d.invoice_line_number(+)
    AND l.org_id = d.org_id(+)
ORDER BY h.invoice_id, l.line_number, d.distribution_line_number, d.invoice_distribution_id
;
