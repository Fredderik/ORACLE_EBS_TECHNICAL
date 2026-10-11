/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pagos.sql                                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
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
    aca.org_id, aca.check_id, aca.check_number, aca.check_date,
    aca.status_lookup_code, aca.payment_type_flag,
    aca.payment_method_code, aca.currency_code moneda_pago,
    aca.amount importe_pago,
    aca.vendor_id, aca.vendor_site_id,
    aca.vendor_name proveedor_registrado,
    aca.vendor_site_code sitio_registrado,
    aca.bank_account_name cuenta_bancaria_nombre,
    aca.ce_bank_acct_use_id, aca.payment_id, aca.payment_instruction_id,
    aca.checkrun_name, aca.void_date,
    aca.cleared_date, aca.cleared_amount,
    aca.description,
    ipa.payment_status estado_iby,
    ipa.payment_service_request_id,
    ipa.payments_complete_flag
FROM ap_checks_all aca,
     iby_payments_all ipa
WHERE
    aca.org_id = :p_org_id
    AND (:p_check_id IS NULL OR aca.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR aca.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR aca.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aca.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aca.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aca.payment_id = ipa.payment_id(+)
ORDER BY aca.check_date, aca.check_id
/
-- Consulta 2: Aplicaciones del pago a facturas y cuotas de vencimiento.
-- PAYMENT_NUM identifica la cuota; la unión evita repetirla por cada cuota.
-- Se conserva el pago sin aplicaciones y la aplicación sin metadatos.
-- Las organizaciones de aplicación/factura se muestran separadas de la del
-- pago para conservar relaciones registradas en escenarios centralizados.
-- Los importes base, de pago y de factura no deben mezclarse.
-- No se excluyen reversiones: una anulación puede añadir un importe negativo.
SELECT
    aca.org_id, aca.check_id, aca.check_number, aca.check_date,
    aca.status_lookup_code, aca.payment_type_flag,
    aca.payment_method_code, aca.currency_code moneda_pago,
    aca.amount importe_pago,
    aca.vendor_id, aca.vendor_site_id,
    aca.vendor_name proveedor_registrado,
    aca.vendor_site_code sitio_registrado,
    aca.bank_account_name cuenta_bancaria_nombre,
    aca.ce_bank_acct_use_id, aca.payment_id, aca.payment_instruction_id,
    aca.checkrun_name, aca.void_date,
    aca.cleared_date, aca.cleared_amount,
    aca.description,
    aipa.invoice_payment_id,
    aipa.org_id organizacion_aplicacion,
    aipa.invoice_id, aia.org_id organizacion_factura,
    aia.invoice_num, aia.invoice_date,
    aia.invoice_currency_code, aia.payment_currency_code,
    aia.invoice_amount importe_factura,
    aipa.payment_num, apsa.due_date,
    apsa.amount_remaining saldo_actual_cuota,
    aipa.amount importe_aplicacion,
    aipa.discount_taken, aipa.discount_lost,
    aipa.invoice_base_amount, aipa.payment_base_amount,
    aipa.accounting_date, aipa.period_name, aipa.set_of_books_id,
    aipa.posted_flag, aipa.accrual_posted_flag, aipa.cash_posted_flag,
    aipa.reversal_flag, aipa.reversal_inv_pmt_id,
    aipa.accounting_event_id,
    aipa.accts_pay_code_combination_id cuenta_pasivo_id
FROM ap_checks_all aca,
     ap_invoice_payments_all aipa,
     ap_invoices_all aia,
     ap_payment_schedules_all apsa
WHERE
    aca.org_id = :p_org_id
    AND (:p_check_id IS NULL OR aca.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR aca.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR aca.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aca.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aca.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aca.check_id = aipa.check_id(+)
    AND aipa.invoice_id = aia.invoice_id(+)
    AND aipa.invoice_id = apsa.invoice_id(+)
    AND aipa.payment_num = apsa.payment_num(+)
ORDER BY aca.check_date, aca.check_id, aipa.invoice_id,
         aipa.payment_num, aipa.invoice_payment_id
/
-- Consulta 3: Historial registrado de eventos del pago.
-- Se consulta separado de las facturas para no multiplicar sus aplicaciones.
-- No equivale al detalle de asientos SLA/GL ni al extracto bancario completo.
SELECT
    aca.org_id, aca.check_id, aca.check_number, aca.check_date,
    aca.status_lookup_code, aca.payment_type_flag,
    aca.payment_method_code, aca.currency_code moneda_pago,
    aca.amount importe_pago,
    aca.vendor_id, aca.vendor_site_id,
    aca.vendor_name proveedor_registrado,
    aca.vendor_site_code sitio_registrado,
    aca.bank_account_name cuenta_bancaria_nombre,
    aca.ce_bank_acct_use_id, aca.payment_id, aca.payment_instruction_id,
    aca.checkrun_name, aca.void_date,
    aca.cleared_date, aca.cleared_amount,
    aca.description,
    apha.payment_history_id,
    apha.org_id organizacion_evento,
    apha.transaction_type, apha.accounting_date,
    apha.posted_flag, apha.matched_flag,
    apha.accounting_event_id, apha.rev_pmt_hist_id,
    apha.pmt_currency_code, apha.bank_currency_code,
    apha.trx_pmt_amount, apha.errors_pmt_amount, apha.charges_pmt_amount,
    apha.trx_bank_amount, apha.errors_bank_amount, apha.charges_bank_amount,
    apha.creation_date fecha_registro_evento
FROM ap_checks_all aca,
     ap_payment_history_all apha
WHERE
    aca.org_id = :p_org_id
    AND (:p_check_id IS NULL OR aca.check_id = :p_check_id)
    AND (:p_check_number IS NULL OR aca.check_number = :p_check_number)
    AND (:p_vendor_id IS NULL OR aca.vendor_id = :p_vendor_id)
    AND (:p_fecha_desde IS NULL
         OR aca.check_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR aca.check_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND aca.check_id = apha.check_id(+)
ORDER BY aca.check_date, aca.check_id, apha.accounting_date, apha.payment_history_id;
