/*
╔════════════════════════════════════════════════════════════════════════════════╗
║  File Name      : configuracion_gl.sql                                         ║
║  Author         : Freddy E. Aparicio M.                                        ║
║  Creation Date  : 09/10/2026                                                   ║
║  Version        : 1.0                                                          ║
║  Description    : Ledgers, open periods and segment definitions.               ║
║                                                                                ║
║  Parameters     : Explicit bind variables.                                     ║
║    - Required:                                                                 ║
║      * p_language (VARCHAR2; EBS code, e.g. US)                                ║
║    - Optionals (NULL means no filter):                                         ║
║      * p_ledger_id (NUMBER; NULL=all ledgers)                                  ║
║                                                                                ║
║  Notes          : Oracle EBS R12 onwards; base table names.                    ║
║                   No runtime certification on an EBS instance.                 ║
║                   Inventory is not filtered by responsibility/data access set. ║
║                   Three queries; slash executes each preceding SELECT.         ║
║                                                                                ║
║  Updates        :                                                              ║
║    - 09/10/2026: Creation - Freddy E. Aparicio M.                              ║
╚════════════════════════════════════════════════════════════════════════════════╝
*/

--Query 1: Physical ledgers, excluding ledger sets.
SELECT gl.ledger_id, gl.name, gl.short_name, gl.description,
       gl.ledger_category_code, gl.currency_code,
       gl.chart_of_accounts_id, gl.period_set_name,
       gl.accounted_period_type, gl.completion_status_code,
       gl.enable_average_balances_flag
  FROM gl_ledgers gl
 WHERE gl.object_type_code = 'L'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.name, gl.ledger_id
/
--Query 2: GL open periods, including adjustment periods when open.
--APPLICATION_ID=101 excludes period statuses from other applications.
SELECT gl.ledger_id, gl.name ledger_name, gps.period_name,
       gps.period_year, gps.period_num, gps.start_date, gps.end_date,
       gps.adjustment_period_flag, gps.closing_status
  FROM gl_ledgers gl
  JOIN gl_period_statuses gps ON gps.ledger_id = gl.ledger_id
 WHERE gl.object_type_code = 'L'
   AND gps.application_id = 101
   AND gps.closing_status = 'O'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.ledger_id, gps.period_year, gps.period_num
/
--Query 3: Display sequence is not the physical SEGMENTn number.
--GL_ACCOUNT=natural account. Each enabled qualifier gets its own row.
--No enabled qualifier produces a NULL qualifier, not a missing segment.
SELECT gl.ledger_id, gl.name ledger_name, gl.chart_of_accounts_id,
       fs.segment_num display_sequence, fs.application_column_name,
       fs.segment_name, fst.form_left_prompt, fst.description,
       fs.enabled_flag, fs.required_flag,
       fs.flex_value_set_id, fvs.flex_value_set_name,
       sav.segment_attribute_type qualifier_code, sav.attribute_value,
       CASE WHEN sav.segment_attribute_type = 'GL_ACCOUNT'
            THEN 'CUENTA_NATURAL'
            ELSE sav.segment_attribute_type END qualifier_meaning
  FROM gl_ledgers gl
  JOIN fnd_id_flex_segments fs
    ON fs.application_id = 101
   AND fs.id_flex_code = 'GL#'
   AND fs.id_flex_num = gl.chart_of_accounts_id
  LEFT JOIN fnd_id_flex_segments_tl fst
    ON fst.application_id = fs.application_id
   AND fst.id_flex_code = fs.id_flex_code
   AND fst.id_flex_num = fs.id_flex_num
   AND fst.application_column_name = fs.application_column_name
   AND fst.language = :p_language
  LEFT JOIN fnd_flex_value_sets fvs ON fvs.flex_value_set_id = fs.flex_value_set_id
  LEFT JOIN fnd_segment_attribute_values sav
    ON sav.application_id = fs.application_id
   AND sav.id_flex_code = fs.id_flex_code
   AND sav.id_flex_num = fs.id_flex_num
   AND sav.application_column_name = fs.application_column_name
   AND sav.attribute_value = 'Y'
 WHERE gl.object_type_code = 'L'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.ledger_id, fs.segment_num, sav.segment_attribute_type;
