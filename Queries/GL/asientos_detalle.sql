/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : asientos_detalle.sql                                        ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 09/10/2026                                                  ║
║  Versión        : 1.2                                                         ║
║  Descripción    : Lote, asiento, líneas y combinación contable.               ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    - Obligatorios:                                                            ║
║      * p_ledger_id (NUMBER)                                                   ║
║      * p_period_name (VARCHAR2)                                               ║
║      * p_language (VARCHAR2; código EBS, por ejemplo US)                      ║
║    - Opcionales (NULL omite el filtro, salvo indicación):                     ║
║      * p_je_batch_id (NUMBER)                                                 ║
║      * p_je_header_id (NUMBER)                                                ║
║      * p_code_combination_id (NUMBER)                                         ║
║      * p_status (VARCHAR2; P=contabilizado, U=sin contabilizar)               ║
║      * p_je_source (VARCHAR2; código interno)                                 ║
║      * p_je_category (VARCHAR2; código interno)                               ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; combinación mediante vista KFV. ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin valores predeterminados del contexto de sesión.         ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                   Una fila por línea; cuenta en CONCATENATED_SEGMENTS.        ║
║                   Consultar el significado en configuracion_gl.sql.           ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    09/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    10/10/2026: Versión 1.1. Español y sintaxis SQL tradicional.               ║
║    10/10/2026: Versión 1.2. Cuenta concatenada mediante vista KFV.            ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

SELECT
    gl.ledger_id,
    gl.name ledger_name,
    gl.currency_code ledger_currency,
    gjb.je_batch_id,
    gjb.name batch_name,
    gjb.description batch_description,
    gjb.status batch_status,
    gjh.je_header_id,
    gjh.name journal_name,
    gjh.description journal_description,
    gjh.status journal_status,
    gjh.actual_flag,
    gjh.period_name,
    gjh.posted_date,
    gjh.je_source source_code,
    gst.user_je_source_name source_name,
    gjh.je_category category_code,
    gct.user_je_category_name category_name,
    gjh.currency_code entered_currency,
    gjh.currency_conversion_type,
    gjh.currency_conversion_date,
    gjh.currency_conversion_rate,
    gjl.je_line_num,
    gjl.effective_date,
    gjl.description line_description,
    gjl.code_combination_id,
    nvl(gjl.entered_dr, 0) entered_dr,
    nvl(gjl.entered_cr, 0) entered_cr,
    nvl(gjl.accounted_dr, 0) accounted_dr,
    nvl(gjl.accounted_cr, 0) accounted_cr,
    nvl(gjl.accounted_dr, 0) - nvl(gjl.accounted_cr, 0) accounted_net,
    gcc.chart_of_accounts_id,
    gcc.description combination_description,
    gcc.gl_account_type account_type,
    gcc.enabled_flag combination_enabled,
    gcc.summary_flag,
    gcc.detail_posting_allowed detail_posting_allowed_flag,
    gcc.concatenated_segments
FROM gl_je_batches gjb,
     gl_je_headers gjh,
     gl_je_lines gjl,
     gl_ledgers gl,
     gl_code_combinations_kfv gcc,
     gl_je_sources_tl gst,
     gl_je_categories_tl gct
WHERE gjh.je_batch_id = gjb.je_batch_id
  AND gjl.je_header_id = gjh.je_header_id
  AND gl.ledger_id = gjh.ledger_id
  AND gcc.code_combination_id = gjl.code_combination_id
  AND gcc.chart_of_accounts_id = gl.chart_of_accounts_id
  AND gst.je_source_name(+) = gjh.je_source
  AND gst.language(+) = :p_language
  AND gct.je_category_name(+) = gjh.je_category
  AND gct.language(+) = :p_language
  AND gl.ledger_id = :p_ledger_id
  AND gjh.period_name = :p_period_name
  AND (:p_je_batch_id IS NULL OR gjb.je_batch_id = :p_je_batch_id)
  AND (:p_je_header_id IS NULL OR gjh.je_header_id = :p_je_header_id)
  AND (:p_code_combination_id IS NULL OR gcc.code_combination_id = :p_code_combination_id)
  AND (:p_status IS NULL OR gjh.status = :p_status)
  AND (:p_je_source IS NULL OR gjh.je_source = :p_je_source)
  AND (:p_je_category IS NULL OR gjh.je_category = :p_je_category)
ORDER BY gjb.je_batch_id, gjh.je_header_id, gjl.je_line_num;
