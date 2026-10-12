/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : documentos_pagables.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Documentos enviados a Payments y pago asociado.             ║
║  Obligatorios   :                                                             ║
║    p_org_id (NUMBER).                                                         ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_payment_service_request_id (NUMBER).                                     ║
║    p_payment_id (NUMBER).                                                     ║
║    p_document_payable_id (NUMBER).                                            ║
║    p_calling_app_id (NUMBER).                                                 ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por documento pagable; conserva documentos aún sin pago.
-- No asumir que todas las referencias son INVOICE_ID de AP.
-- El importe del pago se repite si este agrupa varios documentos.
SELECT
    idpa.document_payable_id, idpa.payment_service_request_id,
    idpa.org_id, idpa.calling_app_id, idpa.pay_proc_trxn_type_code,
    idpa.calling_app_doc_ref_number,
    idpa.calling_app_doc_unique_ref1, idpa.calling_app_doc_unique_ref2,
    idpa.calling_app_doc_unique_ref3, idpa.calling_app_doc_unique_ref4,
    idpa.calling_app_doc_unique_ref5,
    idpa.document_type, idpa.document_status, idpa.document_date,
    idpa.document_amount, idpa.document_currency_code,
    idpa.payment_amount importe_documento_moneda_pago,
    idpa.payment_currency_code, idpa.payment_id,
    ipa.payment_status, ipa.payment_amount importe_total_pago
FROM iby_docs_payable_all idpa, iby_payments_all ipa
WHERE idpa.org_id = :p_org_id
    AND idpa.payment_id = ipa.payment_id(+)
    AND (:p_payment_service_request_id IS NULL OR idpa.payment_service_request_id = :p_payment_service_request_id)
    AND (:p_payment_id IS NULL OR idpa.payment_id = :p_payment_id)
    AND (:p_document_payable_id IS NULL OR idpa.document_payable_id = :p_document_payable_id)
    AND (:p_calling_app_id IS NULL OR idpa.calling_app_id = :p_calling_app_id)
ORDER BY idpa.payment_service_request_id, idpa.document_payable_id;
