/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : extractos_bancarios.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Cabeceras y líneas de extractos bancarios.                  ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio NUMBER: p_bank_account_id.                                     ║
║    Opcionales: p_statement_header_id (NUMBER), p_statement_number (texto).    ║
║    Opcionales: p_fecha_desde, p_fecha_hasta (texto YYYY-MM-DD).               ║
║    NULL omite el filtro; fechas inclusivas del extracto.                      ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Estados originales; no requiere parámetro de idioma.        ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- CE_STATEMENT_HEADERS y CE_STATEMENT_LINES son tablas base.
-- ORG_ID de cabecera está obsoleto en R12; se filtra por cuenta bancaria.
-- No se enlazan los usos por OU: una cuenta puede tener varios.
-- Cada / ejecuta el SELECT anterior, sin ; previo.
-- Consulta 1: Cabeceras y controles registrados.
SELECT
    h.bank_account_id, h.statement_header_id, h.statement_number,
    h.statement_date, h.gl_date, h.currency_code moneda_extracto,
    h.auto_loaded_flag, h.statement_complete_flag,
    h.control_begin_balance, h.control_end_balance,
    h.control_total_dr, h.control_total_cr,
    h.control_dr_line_count, h.control_cr_line_count
FROM ce_statement_headers h
WHERE
    h.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR h.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR h.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR h.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY h.statement_date, h.statement_header_id
/
-- Consulta 2: Cabeceras y líneas; conserva extractos sin líneas.
-- Los controles de cabecera se repiten; no sumarlos en este resultado.
-- No se infiere el signo del movimiento ni se mezclan monedas.
SELECT
    h.bank_account_id, h.statement_header_id, h.statement_number,
    h.statement_date, h.gl_date, h.currency_code moneda_extracto,
    h.auto_loaded_flag, h.statement_complete_flag,
    h.control_begin_balance, h.control_end_balance,
    h.control_total_dr, h.control_total_cr,
    h.control_dr_line_count, h.control_cr_line_count,
    l.statement_line_id, l.line_number, l.trx_date, l.effective_date,
    l.trx_type, l.trx_code_id, l.bank_trx_number, l.trx_text,
    l.amount importe_linea, l.status estado_linea,
    l.currency_code moneda_original, l.original_amount,
    l.exchange_rate_type, l.exchange_rate, l.exchange_rate_date,
    l.charges_amount
FROM
    ce_statement_headers h,
    ce_statement_lines l
WHERE
    h.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR h.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR h.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR h.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.statement_header_id = l.statement_header_id(+)
ORDER BY h.statement_date, h.statement_header_id, l.line_number;
