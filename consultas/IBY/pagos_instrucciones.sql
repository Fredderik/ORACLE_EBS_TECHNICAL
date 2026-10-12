/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : pagos_instrucciones.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Pagos y su instrucción de procesamiento.                    ║
║  Obligatorios   :                                                             ║
║    p_org_id (NUMBER).                                                         ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_payment_service_request_id (NUMBER).                                     ║
║    p_payment_id (NUMBER).                                                     ║
║    p_payment_instruction_id (NUMBER).                                         ║
║    p_payment_status (VARCHAR2(30)).                                           ║
║    p_fecha_desde (VARCHAR2(10), YYYY-MM-DD).                                  ║
║    p_fecha_hasta (VARCHAR2(10), YYYY-MM-DD).                                  ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por pago. Se conserva el pago sin instrucción asignada.
-- Una instrucción puede agrupar varios pagos y solicitudes.
-- TRANSMITTED no equivale a conciliado ni confirma liquidación bancaria.
SELECT
    ipa.payment_id, ipa.payment_service_request_id,
    ipa.org_id, ipa.legal_entity_id, ipa.payment_status,
    ipa.payment_function, ipa.payment_method_code,
    ipa.payment_date, ipa.payment_amount, ipa.payment_currency_code,
    ipa.payee_party_id, ipa.ext_payee_id,
    ipa.internal_bank_account_id, ipa.external_bank_account_id,
    ipa.payment_instruction_id,
    ipia.payment_instruction_status, ipia.payments_complete_code,
    ipia.transmission_date, ipia.acknowledgement_date,
    ipia.bank_assigned_ref_code
FROM iby_payments_all ipa, iby_pay_instructions_all ipia
WHERE ipa.org_id = :p_org_id
    AND ipa.payment_instruction_id = ipia.payment_instruction_id(+)
    AND (:p_payment_service_request_id IS NULL OR ipa.payment_service_request_id = :p_payment_service_request_id)
    AND (:p_payment_id IS NULL OR ipa.payment_id = :p_payment_id)
    AND (:p_payment_instruction_id IS NULL OR ipa.payment_instruction_id = :p_payment_instruction_id)
    AND (:p_payment_status IS NULL OR ipa.payment_status = :p_payment_status)
    AND (:p_fecha_desde IS NULL OR ipa.payment_date >= TO_DATE(:p_fecha_desde, 'YYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL OR ipa.payment_date < TO_DATE(:p_fecha_hasta, 'YYYY-MM-DD') + 1)
ORDER BY ipa.payment_date, ipa.payment_id;
