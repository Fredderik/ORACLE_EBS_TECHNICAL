/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : impuestos_transaccion.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Líneas fiscales y distribuciones de una transacción.        ║
║  Obligatorios   :                                                             ║
║    p_application_id (NUMBER).                                                 ║
║    p_entity_code (VARCHAR2(30)).                                              ║
║    p_event_class_code (VARCHAR2(30)).                                         ║
║    p_trx_id (NUMBER).                                                         ║
║    p_internal_organization_id (NUMBER).                                       ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_tax_line_id (NUMBER).                                                    ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Una fila por línea fiscal. Incluye cancelaciones para diagnóstico.
-- Conservar moneda e indicadores al analizar importes.
SELECT
    zl.tax_line_id, zl.application_id, zl.entity_code,
    zl.event_class_code, zl.trx_id, zl.internal_organization_id,
    zl.trx_line_id, zl.trx_level_type, zl.trx_line_number,
    zl.tax_regime_code, zl.tax, zl.tax_status_code,
    zl.tax_rate_id, zl.tax_rate_code, zl.tax_rate,
    zl.trx_currency_code, zl.taxable_amt, zl.tax_amt,
    zl.cancel_flag, zl.delete_flag, zl.tax_amt_included_flag,
    zl.mrc_tax_line_flag
FROM zx_lines zl
WHERE
    zl.application_id = :p_application_id
    AND zl.entity_code = :p_entity_code
    AND zl.event_class_code = :p_event_class_code
    AND zl.trx_id = :p_trx_id
    AND zl.internal_organization_id = :p_internal_organization_id
    AND (:p_tax_line_id IS NULL OR zl.tax_line_id = :p_tax_line_id)
ORDER BY zl.trx_line_id, zl.tax_line_id
/
-- 2. Una fila por distribución recuperable/no recuperable existente.
-- No todas las aplicaciones generan estas distribuciones.
-- No sumar TAX_AMT de la cabecera multiplicado por las distribuciones.
SELECT
    zl.tax_line_id, zl.trx_id, zl.trx_line_id,
    zl.trx_currency_code, zl.tax_regime_code, zl.tax,
    zrnd.rec_nrec_tax_dist_id, zrnd.trx_line_dist_id,
    zrnd.rec_nrec_tax_dist_number, zrnd.recoverable_flag,
    zrnd.rec_nrec_rate, zrnd.rec_nrec_tax_amt,
    zrnd.rec_nrec_tax_amt_funcl_curr,
    zrnd.reverse_flag, zrnd.reversed_tax_dist_id
FROM zx_lines zl, zx_rec_nrec_dist zrnd
WHERE
    zl.application_id = :p_application_id
    AND zl.entity_code = :p_entity_code
    AND zl.event_class_code = :p_event_class_code
    AND zl.trx_id = :p_trx_id
    AND zl.internal_organization_id = :p_internal_organization_id
    AND (:p_tax_line_id IS NULL OR zl.tax_line_id = :p_tax_line_id)
    AND zl.tax_line_id = zrnd.tax_line_id
ORDER BY zl.tax_line_id, zrnd.rec_nrec_tax_dist_id;
