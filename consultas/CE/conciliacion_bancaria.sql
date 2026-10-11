/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : conciliacion_bancaria.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Historial y referencias de conciliación.                    ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio NUMBER: p_bank_account_id.                                     ║
║    Opcionales: p_statement_header_id (NUMBER), p_statement_number (texto).    ║
║    Opcionales: p_fecha_desde, p_fecha_hasta (texto YYYY-MM-DD).               ║
║    NULL omite el filtro; fechas inclusivas del extracto.                      ║
║    Opcionales NUMBER: p_statement_line_id, p_org_id.                          ║
║    Opcionales texto: p_reference_type, p_current_record_flag (Y/N),           ║
║    p_status_flag (M/U). NULL permite todo el historial.                       ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Estados originales; no requiere parámetro de idioma.        ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Cada fila corresponde a una acción registrada, no a un saldo pendiente.
-- Para coincidencias vigentes: p_current_record_flag=Y y p_status_flag=M.
-- El estado de la línea y el del registro de conciliación son distintos.
-- No se suman los importes históricos ni se deduplican acciones con DISTINCT.
-- Solo devuelve líneas con historial. Las demás se ven en extractos_bancarios.sql.
-- p_org_id filtra la organización del registro de conciliación; con NULL
-- conserva también registros sin organización (por ejemplo, ciertas fuentes GL).
-- REFERENCE_ID depende de REFERENCE_TYPE:
-- PAYMENT: AP_CHECKS_ALL.CHECK_ID.
-- RECEIPT: AR_CASH_RECEIPT_HISTORY_ALL.CASH_RECEIPT_HISTORY_ID (no recibo ID).
-- JE_LINE: GL_JE_LINES.JE_LINE_NUM junto con JE_HEADER_ID.
-- STATEMENT: CE_STATEMENT_LINES.STATEMENT_LINE_ID.
-- Se conservan otros tipos sin intentar asociarlos por ID a una tabla incorrecta.
SELECT
    csh.bank_account_id, csh.statement_header_id, csh.statement_number,
    csh.statement_date, csh.currency_code moneda_extracto,
    csl.statement_line_id, csl.line_number,
    csl.trx_date, csl.trx_type, csl.bank_trx_number,
    csl.amount importe_linea, csl.status estado_linea,
    csra.reference_type, csra.reference_id, csra.je_header_id,
    csra.org_id organizacion_referencia, csra.legal_entity_id,
    csra.reference_status, csra.status_flag, csra.current_record_flag,
    csra.auto_reconciled_flag, csra.amount importe_conciliacion,
    csra.creation_date fecha_registro, csra.created_by,
    csra.last_update_date, csra.last_updated_by, csra.request_id
FROM
    ce_statement_headers csh,
    ce_statement_lines csl,
    ce_statement_reconcils_all csra
WHERE
    csh.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR csh.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR csh.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR csh.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR csh.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND csh.statement_header_id = csl.statement_header_id
    AND csl.statement_line_id = csra.statement_line_id
    AND (:p_statement_line_id IS NULL OR csl.statement_line_id = :p_statement_line_id)
    AND (:p_org_id IS NULL OR csra.org_id = :p_org_id)
    AND (:p_reference_type IS NULL OR csra.reference_type = :p_reference_type)
    AND (:p_current_record_flag IS NULL
         OR csra.current_record_flag = :p_current_record_flag)
    AND (:p_status_flag IS NULL OR csra.status_flag = :p_status_flag)
ORDER BY csh.statement_date, csh.statement_header_id, csl.line_number,
         csra.creation_date, csra.reference_type, csra.reference_id, csra.je_header_id;
