/*
╔══════════════════════════════════════════════════════════════════════╗
║  File Name      : asientos_detalle.sql                               ║
║  Author         : Freddy E. Aparicio M.                              ║
║  Creation Date  : 09/10/2026                                         ║
║  Version        : 1.0                                                ║
║  Description    : Batch, journal, lines and account combination.     ║
║                                                                      ║
║  Parameters     : Explicit bind variables.                           ║
║    - Required:                                                       ║
║      * p_ledger_id (NUMBER)                                          ║
║      * p_period_name (VARCHAR2)                                      ║
║      * p_language (VARCHAR2; EBS code, e.g. US)                      ║
║    - Optionals (NULL means no filter):                               ║
║      * p_je_batch_id (NUMBER)                                        ║
║      * p_je_header_id (NUMBER)                                       ║
║      * p_code_combination_id (NUMBER)                                ║
║      * p_status (VARCHAR2; P=posted, U=unposted)                     ║
║      * p_je_source (VARCHAR2; internal code)                         ║
║      * p_je_category (VARCHAR2; internal code)                       ║
║                                                                      ║
║  Notes          : Oracle EBS R12 onwards; base table names.          ║
║                   No runtime certification on an EBS instance.       ║
║                   One row per journal line; all 30 segment values.   ║
║                   Use configuracion_gl.sql for segment meanings.     ║
║                                                                      ║
║  Updates        :                                                    ║
║    - 09/10/2026: Creation - Freddy E. Aparicio M.                    ║
╚══════════════════════════════════════════════════════════════════════╝
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
    gcc.account_type,
    gcc.enabled_flag combination_enabled,
    gcc.summary_flag,
    gcc.detail_posting_allowed_flag,
    gcc.segment1,
    gcc.segment2,
    gcc.segment3,
    gcc.segment4,
    gcc.segment5,
    gcc.segment6,
    gcc.segment7,
    gcc.segment8,
    gcc.segment9,
    gcc.segment10,
    gcc.segment11,
    gcc.segment12,
    gcc.segment13,
    gcc.segment14,
    gcc.segment15,
    gcc.segment16,
    gcc.segment17,
    gcc.segment18,
    gcc.segment19,
    gcc.segment20,
    gcc.segment21,
    gcc.segment22,
    gcc.segment23,
    gcc.segment24,
    gcc.segment25,
    gcc.segment26,
    gcc.segment27,
    gcc.segment28,
    gcc.segment29,
    gcc.segment30
FROM gl_je_batches gjb
JOIN gl_je_headers gjh ON gjh.je_batch_id = gjb.je_batch_id
JOIN gl_je_lines gjl ON gjl.je_header_id = gjh.je_header_id
JOIN gl_ledgers gl ON gl.ledger_id = gjh.ledger_id
JOIN gl_code_combinations gcc
    ON gcc.code_combination_id = gjl.code_combination_id
   AND gcc.chart_of_accounts_id = gl.chart_of_accounts_id
LEFT JOIN gl_je_sources_tl gst
    ON gst.je_source_name = gjh.je_source
   AND gst.language = :p_language
LEFT JOIN gl_je_categories_tl gct
    ON gct.je_category_name = gjh.je_category
   AND gct.language = :p_language
WHERE gl.ledger_id = :p_ledger_id
  AND gjh.period_name = :p_period_name
  AND (:p_je_batch_id IS NULL OR gjb.je_batch_id = :p_je_batch_id)
  AND (:p_je_header_id IS NULL OR gjh.je_header_id = :p_je_header_id)
  AND (:p_code_combination_id IS NULL OR gcc.code_combination_id = :p_code_combination_id)
  AND (:p_status IS NULL OR gjh.status = :p_status)
  AND (:p_je_source IS NULL OR gjh.je_source = :p_je_source)
  AND (:p_je_category IS NULL OR gjh.je_category = :p_je_category)
ORDER BY gjb.je_batch_id, gjh.je_header_id, gjl.je_line_num;
