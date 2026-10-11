/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : extractos_bancarios.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- CE_STATEMENT_HEADERS y CE_STATEMENT_LINES son tablas base.
-- ORG_ID de cabecera está obsoleto en R12; se filtra por cuenta bancaria.
-- No se enlazan los usos por OU: una cuenta puede tener varios.
-- Cada / ejecuta el SELECT anterior, sin ; previo.
-- Consulta 1: Cabeceras y controles registrados.
SELECT
    csh.bank_account_id, csh.statement_header_id, csh.statement_number,
    csh.statement_date, csh.gl_date, csh.currency_code moneda_extracto,
    csh.auto_loaded_flag, csh.statement_complete_flag,
    csh.control_begin_balance, csh.control_end_balance,
    csh.control_total_dr, csh.control_total_cr,
    csh.control_dr_line_count, csh.control_cr_line_count
FROM ce_statement_headers csh
WHERE
    csh.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR csh.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR csh.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR csh.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR csh.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY csh.statement_date, csh.statement_header_id
/
-- Consulta 2: Cabeceras y líneas; conserva extractos sin líneas.
-- Los controles de cabecera se repiten; no sumarlos en este resultado.
-- No se infiere el signo del movimiento ni se mezclan monedas.
SELECT
    csh.bank_account_id, csh.statement_header_id, csh.statement_number,
    csh.statement_date, csh.gl_date, csh.currency_code moneda_extracto,
    csh.auto_loaded_flag, csh.statement_complete_flag,
    csh.control_begin_balance, csh.control_end_balance,
    csh.control_total_dr, csh.control_total_cr,
    csh.control_dr_line_count, csh.control_cr_line_count,
    csl.statement_line_id, csl.line_number, csl.trx_date, csl.effective_date,
    csl.trx_type, csl.trx_code_id, csl.bank_trx_number, csl.trx_text,
    csl.amount importe_linea, csl.status estado_linea,
    csl.currency_code moneda_original, csl.original_amount,
    csl.exchange_rate_type, csl.exchange_rate, csl.exchange_rate_date,
    csl.charges_amount
FROM
    ce_statement_headers csh,
    ce_statement_lines csl
WHERE
    csh.bank_account_id = :p_bank_account_id
    AND (:p_statement_header_id IS NULL
         OR csh.statement_header_id = :p_statement_header_id)
    AND (:p_statement_number IS NULL OR csh.statement_number = :p_statement_number)
    AND (:p_fecha_desde IS NULL
         OR csh.statement_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR csh.statement_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND csh.statement_header_id = csl.statement_header_id(+)
ORDER BY csh.statement_date, csh.statement_header_id, csl.line_number;
