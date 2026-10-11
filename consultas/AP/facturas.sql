/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : facturas.sql                                                ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
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
    aia.org_id,
    aia.set_of_books_id,
    aia.invoice_id,
    aia.invoice_num,
    aia.invoice_type_lookup_code,
    aia.invoice_date,
    aia.gl_date,
    aia.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name proveedor_nombre,
    aia.vendor_site_id,
    assa.vendor_site_code sitio_proveedor,
    aia.invoice_currency_code,
    aia.payment_currency_code,
    aia.invoice_amount importe_factura,
    aia.base_amount importe_base_factura,
    aia.amount_paid importe_pagado,
    aia.payment_status_flag,
    aia.wfapproval_status,
    aia.cancelled_date,
    aia.source,
    aia.description descripcion_factura,
    aia.terms_id,
    att.name condiciones_pago,
    aia.terms_date,
    aia.accts_pay_code_combination_id cuenta_pasivo_id
FROM
    ap_invoices_all       aia,
    ap_suppliers          aps,
    ap_supplier_sites_all assa,
    ap_terms_tl           att
WHERE
        aia.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR aia.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR aia.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR aia.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aia.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aia.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aia.vendor_id = aps.vendor_id(+)
    AND aia.vendor_site_id = assa.vendor_site_id(+)
    AND aia.vendor_id = assa.vendor_id(+)
    AND aia.org_id = assa.org_id(+)
    AND aia.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
ORDER BY aia.invoice_id
/
-- Consulta 2: Cabecera y líneas (una fila por línea, si existe).
SELECT
    aia.org_id,
    aia.set_of_books_id,
    aia.invoice_id,
    aia.invoice_num,
    aia.invoice_type_lookup_code,
    aia.invoice_date,
    aia.gl_date,
    aia.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name proveedor_nombre,
    aia.vendor_site_id,
    assa.vendor_site_code sitio_proveedor,
    aia.invoice_currency_code,
    aia.payment_currency_code,
    aia.invoice_amount importe_factura,
    aia.base_amount importe_base_factura,
    aia.amount_paid importe_pagado,
    aia.payment_status_flag,
    aia.wfapproval_status,
    aia.cancelled_date,
    aia.source,
    aia.description descripcion_factura,
    aia.terms_id,
    att.name condiciones_pago,
    aia.terms_date,
    aia.accts_pay_code_combination_id cuenta_pasivo_id,
    aila.line_number numero_linea,
    aila.line_type_lookup_code tipo_linea,
    aila.description descripcion_linea,
    aila.amount importe_linea,
    aila.base_amount importe_base_linea,
    aila.accounting_date fecha_contable_linea,
    aila.quantity_invoiced,
    aila.unit_price,
    aila.unit_meas_lookup_code,
    aila.discarded_flag,
    aila.cancelled_flag,
    aila.po_header_id,
    aila.po_line_id,
    aila.po_line_location_id,
    aila.po_distribution_id,
    aila.rcv_transaction_id
FROM
    ap_invoices_all       aia,
    ap_suppliers          aps,
    ap_supplier_sites_all assa,
    ap_terms_tl           att,
    ap_invoice_lines_all aila
WHERE
        aia.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR aia.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR aia.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR aia.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aia.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aia.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aia.vendor_id = aps.vendor_id(+)
    AND aia.vendor_site_id = assa.vendor_site_id(+)
    AND aia.vendor_id = assa.vendor_id(+)
    AND aia.org_id = assa.org_id(+)
    AND aia.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
    AND aia.invoice_id = aila.invoice_id(+)
    AND aia.org_id = aila.org_id(+)
ORDER BY aia.invoice_id, aila.line_number
/
-- Consulta 3: Cabecera, líneas y distribuciones (una fila por distribución, si existe).
SELECT
    aia.org_id,
    aia.set_of_books_id,
    aia.invoice_id,
    aia.invoice_num,
    aia.invoice_type_lookup_code,
    aia.invoice_date,
    aia.gl_date,
    aia.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name proveedor_nombre,
    aia.vendor_site_id,
    assa.vendor_site_code sitio_proveedor,
    aia.invoice_currency_code,
    aia.payment_currency_code,
    aia.invoice_amount importe_factura,
    aia.base_amount importe_base_factura,
    aia.amount_paid importe_pagado,
    aia.payment_status_flag,
    aia.wfapproval_status,
    aia.cancelled_date,
    aia.source,
    aia.description descripcion_factura,
    aia.terms_id,
    att.name condiciones_pago,
    aia.terms_date,
    aia.accts_pay_code_combination_id cuenta_pasivo_id,
    aila.line_number numero_linea,
    aila.line_type_lookup_code tipo_linea,
    aila.description descripcion_linea,
    aila.amount importe_linea,
    aila.base_amount importe_base_linea,
    aila.accounting_date fecha_contable_linea,
    aila.quantity_invoiced,
    aila.unit_price,
    aila.unit_meas_lookup_code,
    aila.discarded_flag,
    aila.cancelled_flag,
    aila.po_header_id,
    aila.po_line_id,
    aila.po_line_location_id,
    aila.po_distribution_id,
    aila.rcv_transaction_id,
    aida.invoice_distribution_id,
    aida.distribution_line_number numero_distribucion,
    aida.line_type_lookup_code tipo_distribucion,
    aida.description descripcion_distribucion,
    aida.amount importe_distribucion,
    aida.base_amount importe_base_distribucion,
    aida.accounting_date fecha_contable_distribucion,
    aida.period_name,
    aida.dist_code_combination_id cuenta_distribucion_id,
    aida.posted_flag,
    aida.match_status_flag,
    aida.reversal_flag,
    aida.parent_reversal_id,
    aida.po_distribution_id oc_distribucion_id,
    aida.project_id,
    aida.task_id,
    aida.expenditure_type
FROM
    ap_invoices_all       aia,
    ap_suppliers          aps,
    ap_supplier_sites_all assa,
    ap_terms_tl           att,
    ap_invoice_lines_all aila,
    ap_invoice_distributions_all aida
WHERE
        aia.org_id = :p_org_id
    AND (:p_invoice_id IS NULL OR aia.invoice_id = :p_invoice_id)
    AND (:p_invoice_num IS NULL OR aia.invoice_num = :p_invoice_num)
    AND (:p_vendor_id IS NULL OR aia.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aia.invoice_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aia.invoice_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aia.vendor_id = aps.vendor_id(+)
    AND aia.vendor_site_id = assa.vendor_site_id(+)
    AND aia.vendor_id = assa.vendor_id(+)
    AND aia.org_id = assa.org_id(+)
    AND aia.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
    AND aia.invoice_id = aila.invoice_id(+)
    AND aia.org_id = aila.org_id(+)
    AND aila.invoice_id = aida.invoice_id(+)
    AND aila.line_number = aida.invoice_line_number(+)
    AND aila.org_id = aida.org_id(+)
ORDER BY aia.invoice_id, aila.line_number, aida.distribution_line_number, aida.invoice_distribution_id
;
