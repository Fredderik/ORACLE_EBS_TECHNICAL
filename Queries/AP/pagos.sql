/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pagos.sql                                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Pagos, facturas aplicadas e historial AP.                   ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_org_id (NUMBER; unidad operativa del pago).                 ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_check_id, p_check_number, p_vendor_id (NUMBER).                        ║
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

-- No necesita parámetro de idioma: muestra códigos y nombres almacenados.
-- AP_CHECKS_ALL incluye pagos electrónicos, cheques y reembolsos.
-- Los filtros se aplican al pago y a CHECK_DATE en los tres resultados.
-- El número de pago no es una clave única; usar CHECK_ID para uno específico.
-- Se incluyen pagos anulados y aplicaciones de reversión con su signo.
-- No sumar importe_pago repetido en aplicaciones o historial.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Cabecera del pago y referencia opcional a Oracle Payments.
-- Proveedor, sitio y nombre bancario son los guardados con el pago.
SELECT
    c.org_id, c.check_id, c.check_number, c.check_date,
    c.status_lookup_code, c.payment_type_flag,
    c.payment_method_code, c.currency_code moneda_pago,
    c.amount importe_pago,
    c.vendor_id, c.vendor_site_id,
    c.vendor_name proveedor_registrado,
    c.vendor_site_code sitio_registrado,
    c.bank_account_name cuenta_bancaria_nombre,
    c.ce_bank_acct_use_id, c.payment_id, c.payment_instruction_id,
    c.checkrun_name, c.void_date,
    c.cleared_date, c.cleared_amount,
    c.description,
    ib.payment_status estado_iby,
    ib.payment_service_request_id,
    ib.payments_complete_flag
FROM ap_checks_all c,
     iby_payments_all ib
WHERE
    c.org_id = :p_org_id
    AND (:p_check_id IS NULL OR c.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR c.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR c.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR c.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR c.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND c.payment_id = ib.payment_id(+)
ORDER BY c.check_date, c.check_id
/
-- Consulta 2: Aplicaciones del pago a facturas y cuotas de vencimiento.
-- PAYMENT_NUM identifica la cuota; la unión evita repetirla por cada cuota.
-- Se conserva el pago sin aplicaciones y la aplicación sin metadatos.
-- Las organizaciones de aplicación/factura se muestran separadas de la del
-- pago para conservar relaciones registradas en escenarios centralizados.
-- Los importes base, de pago y de factura no deben mezclarse.
-- No se excluyen reversiones: una anulación puede añadir un importe negativo.
SELECT
    c.org_id, c.check_id, c.check_number, c.check_date,
    c.status_lookup_code, c.payment_type_flag,
    c.payment_method_code, c.currency_code moneda_pago,
    c.amount importe_pago,
    c.vendor_id, c.vendor_site_id,
    c.vendor_name proveedor_registrado,
    c.vendor_site_code sitio_registrado,
    c.bank_account_name cuenta_bancaria_nombre,
    c.ce_bank_acct_use_id, c.payment_id, c.payment_instruction_id,
    c.checkrun_name, c.void_date,
    c.cleared_date, c.cleared_amount,
    c.description,
    ip.invoice_payment_id,
    ip.org_id organizacion_aplicacion,
    ip.invoice_id, i.org_id organizacion_factura,
    i.invoice_num, i.invoice_date,
    i.invoice_currency_code, i.payment_currency_code,
    i.invoice_amount importe_factura,
    ip.payment_num, ps.due_date,
    ps.amount_remaining saldo_actual_cuota,
    ip.amount importe_aplicacion,
    ip.discount_taken, ip.discount_lost,
    ip.invoice_base_amount, ip.payment_base_amount,
    ip.accounting_date, ip.period_name, ip.set_of_books_id,
    ip.posted_flag, ip.accrual_posted_flag, ip.cash_posted_flag,
    ip.reversal_flag, ip.reversal_inv_pmt_id,
    ip.accounting_event_id,
    ip.accts_pay_code_combination_id cuenta_pasivo_id
FROM ap_checks_all c,
     ap_invoice_payments_all ip,
     ap_invoices_all i,
     ap_payment_schedules_all ps
WHERE
    c.org_id = :p_org_id
    AND (:p_check_id IS NULL OR c.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR c.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR c.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR c.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR c.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND c.check_id = ip.check_id(+)
    AND ip.invoice_id = i.invoice_id(+)
    AND ip.invoice_id = ps.invoice_id(+)
    AND ip.payment_num = ps.payment_num(+)
ORDER BY c.check_date, c.check_id, ip.invoice_id,
         ip.payment_num, ip.invoice_payment_id
/
-- Consulta 3: Historial registrado de eventos del pago.
-- Se consulta separado de las facturas para no multiplicar sus aplicaciones.
-- No equivale al detalle de asientos SLA/GL ni al extracto bancario completo.
SELECT
    c.org_id, c.check_id, c.check_number, c.check_date,
    c.status_lookup_code, c.payment_type_flag,
    c.payment_method_code, c.currency_code moneda_pago,
    c.amount importe_pago,
    c.vendor_id, c.vendor_site_id,
    c.vendor_name proveedor_registrado,
    c.vendor_site_code sitio_registrado,
    c.bank_account_name cuenta_bancaria_nombre,
    c.ce_bank_acct_use_id, c.payment_id, c.payment_instruction_id,
    c.checkrun_name, c.void_date,
    c.cleared_date, c.cleared_amount,
    c.description,
    ph.payment_history_id,
    ph.org_id organizacion_evento,
    ph.transaction_type, ph.accounting_date,
    ph.posted_flag, ph.matched_flag,
    ph.accounting_event_id, ph.rev_pmt_hist_id,
    ph.pmt_currency_code, ph.bank_currency_code,
    ph.trx_pmt_amount, ph.errors_pmt_amount, ph.charges_pmt_amount,
    ph.trx_bank_amount, ph.errors_bank_amount, ph.charges_bank_amount,
    ph.creation_date fecha_registro_evento
FROM ap_checks_all c,
     ap_payment_history_all ph
WHERE
    c.org_id = :p_org_id
    AND (:p_check_id IS NULL OR c.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR c.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR c.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR c.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR c.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND c.check_id = ph.check_id(+)
ORDER BY c.check_date, c.check_id, ph.accounting_date, ph.payment_history_id;
