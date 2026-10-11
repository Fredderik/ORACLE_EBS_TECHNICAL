/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : conciliacion_bancaria.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
    h.bank_account_id, h.statement_header_id, h.statement_number,
    h.statement_date, h.currency_code moneda_extracto,
    l.statement_line_id, l.line_number,
    l.trx_date, l.trx_type, l.bank_trx_number,
    l.amount importe_linea, l.status estado_linea,
    r.reference_type, r.reference_id, r.je_header_id,
    r.org_id organizacion_referencia, r.legal_entity_id,
    r.reference_status, r.status_flag, r.current_record_flag,
    r.auto_reconciled_flag, r.amount importe_conciliacion,
    r.creation_date fecha_registro, r.created_by,
    r.last_update_date, r.last_updated_by, r.request_id
FROM
    ce_statement_headers h,
    ce_statement_lines l,
    ce_statement_reconcils_all r
WHERE
    h.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR h.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR h.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR h.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.statement_header_id = l.statement_header_id
    AND l.statement_line_id = r.statement_line_id
    AND (:p_statement_line_id IS NULL OR l.statement_line_id = :p_statement_line_id)
    AND (:p_org_id IS NULL OR r.org_id = :p_org_id)
    AND (:p_reference_type IS NULL OR r.reference_type = :p_reference_type)
    AND (:p_current_record_flag IS NULL
         OR r.current_record_flag = :p_current_record_flag)
    AND (:p_status_flag IS NULL OR r.status_flag = :p_status_flag)
ORDER BY h.statement_date, h.statement_header_id, l.line_number,
         r.creation_date, r.reference_type, r.reference_id, r.je_header_id;
