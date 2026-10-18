/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_operaciones.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Revisar factura, cuotas, recibo, aplicaciones y ajustes.
║ NUMBER: p_org_id obligatorio; p_customer_trx_id y p_cash_receipt_id.
║ Declarar ambos IDs; usar NULL para omitir su resultado, sin ampliar filtros.
║ Oracle EBS R12.1/R12.2. Pendiente ejecución nativa.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SELECT rcta.customer_trx_id, rcta.trx_number, rcta.complete_flag,
       rcta.bill_to_customer_id, rcta.invoice_currency_code, rcta.trx_date
FROM ra_customer_trx_all rcta
WHERE rcta.org_id = :p_org_id AND rcta.customer_trx_id = :p_customer_trx_id
/

-- Cada cuota tiene su PAYMENT_SCHEDULE_ID; no asumir una cuota por factura.
SELECT apsa.payment_schedule_id, apsa.customer_trx_id, apsa.terms_sequence_number,
       apsa.class, apsa.status, apsa.invoice_currency_code,
       apsa.amount_due_original, apsa.amount_due_remaining, apsa.due_date
FROM ar_payment_schedules_all apsa
WHERE apsa.org_id = :p_org_id AND apsa.customer_trx_id = :p_customer_trx_id
ORDER BY apsa.terms_sequence_number
/

SELECT acra.cash_receipt_id, acra.receipt_number, acra.pay_from_customer,
       acra.amount, acra.currency_code, acra.status, acra.receipt_date,
       acra.reversal_date, acra.remit_bank_acct_use_id
FROM ar_cash_receipts_all acra
WHERE acra.org_id = :p_org_id AND acra.cash_receipt_id = :p_cash_receipt_id
/

-- Incluye historial y contrapartidas; no sumar todas las filas como cobros nuevos.
SELECT araa.receivable_application_id, araa.cash_receipt_id,
       araa.applied_customer_trx_id, araa.applied_payment_schedule_id,
       araa.application_type, araa.status, araa.display,
       araa.amount_applied, araa.apply_date, araa.gl_date
FROM ar_receivable_applications_all araa
WHERE araa.org_id = :p_org_id AND araa.cash_receipt_id = :p_cash_receipt_id
ORDER BY araa.receivable_application_id
/

SELECT aaa.adjustment_id, aaa.adjustment_number, aaa.payment_schedule_id,
       aaa.type, aaa.amount, aaa.status, aaa.receivables_trx_id,
       aaa.apply_date, aaa.gl_date
FROM ar_adjustments_all aaa
WHERE aaa.org_id = :p_org_id AND aaa.customer_trx_id = :p_customer_trx_id
ORDER BY aaa.adjustment_id
/
