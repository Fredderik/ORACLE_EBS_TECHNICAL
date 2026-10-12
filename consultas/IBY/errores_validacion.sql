/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : errores_validacion.sql                                      ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Errores de una entidad de procesamiento.                    ║
║  Obligatorios   :                                                             ║
║    p_transaction_type (VARCHAR2(30)).                                         ║
║    p_transaction_id (NUMBER).                                                 ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_error_status (VARCHAR2(30)).                                             ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- El identificador se interpreta junto con el tipo, nunca por separado.
-- Tipos: DOCUMENT_PAYABLE, PAYMENT o PAYMENT_INSTRUCTION.
-- Consultar las claves obtenidas en los otros scripts de IBY.
SELECT
    ite.transaction_error_id, ite.transaction_type, ite.transaction_id,
    ite.error_code, ite.error_date, ite.error_status,
    ite.calling_app_id, ite.pay_proc_trxn_type_code,
    ite.calling_app_doc_unique_ref1,
    ite.override_allowed_on_error_flag, ite.do_not_apply_error_flag
FROM iby_transaction_errors ite
WHERE ite.transaction_type = :p_transaction_type
    AND ite.transaction_id = :p_transaction_id
    AND (:p_error_status IS NULL OR ite.error_status = :p_error_status)
ORDER BY ite.error_date, ite.transaction_error_id;
