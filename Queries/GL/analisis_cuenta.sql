/*
╔═════════════════════════════════════════════════════════════════════════════╗
║  File Name      : analisis_cuenta.sql                                       ║
║  Author         : Freddy E. Aparicio M.                                     ║
║  Creation Date  : 09/10/2026                                                ║
║  Version        : 1.0                                                       ║
║  Description    : Posted account detail versus GL_BALANCES.                 ║
║                                                                             ║
║  Parameters     : Explicit bind variables.                                  ║
║    - Required:                                                              ║
║      * p_ledger_id (NUMBER)                                                 ║
║      * p_period_name (VARCHAR2; exact GL period)                            ║
║      * p_account_value (VARCHAR2; natural account, keep leading zeros)      ║
║    - Optionals (NULL means no filter):                                      ║
║      * p_code_combination_id (NUMBER; restrict one combination)             ║
║      * p_tolerance (NUMBER; NULL=0.01, only Query 2)                        ║
║                                                                             ║
║  Notes          : Oracle EBS R12 onwards; base table names.                 ║
║                   No runtime certification on an EBS instance.              ║
║                   Actual posted journals; ledger currency; detail accounts. ║
║                   No source/category/date subfilter: same balance scope.    ║
║                   GL_ACCOUNT qualifier determines SEGMENT1..SEGMENT30.      ║
║                   Historical disabled combinations remain included.         ║
║                                                                             ║
║  Updates        :                                                           ║
║    - 09/10/2026: Creation - Freddy E. Aparicio M.                           ║
╚═════════════════════════════════════════════════════════════════════════════╝
*/

--Query 1: Period detail. Analytic totals REPEAT; do not sum those columns.
--All entered currencies except STAT contribute their ACCOUNTED amounts.
--For zero activity Query 1 can be empty; inspect Query 2.
WITH ledger_scope AS (
    SELECT gl.ledger_id, gl.name ledger_name, gl.currency_code,
           gl.chart_of_accounts_id,
           (SELECT sav.application_column_name
              FROM fnd_segment_attribute_values sav
             WHERE sav.application_id = 101
               AND sav.id_flex_code = 'GL#'
               AND sav.id_flex_num = gl.chart_of_accounts_id
               AND sav.segment_attribute_type = 'GL_ACCOUNT'
               AND sav.attribute_value = 'Y') account_column
      FROM gl_ledgers gl
     WHERE gl.ledger_id = :p_ledger_id
       AND gl.object_type_code = 'L'
), selected_accounts AS (
    SELECT ls.ledger_id, ls.ledger_name, ls.currency_code,
           ls.account_column, gcc.code_combination_id,
           gcc.description combination_description, gcc.account_type,
           CASE ls.account_column
            WHEN 'SEGMENT1' THEN gcc.segment1
            WHEN 'SEGMENT2' THEN gcc.segment2
            WHEN 'SEGMENT3' THEN gcc.segment3
            WHEN 'SEGMENT4' THEN gcc.segment4
            WHEN 'SEGMENT5' THEN gcc.segment5
            WHEN 'SEGMENT6' THEN gcc.segment6
            WHEN 'SEGMENT7' THEN gcc.segment7
            WHEN 'SEGMENT8' THEN gcc.segment8
            WHEN 'SEGMENT9' THEN gcc.segment9
            WHEN 'SEGMENT10' THEN gcc.segment10
            WHEN 'SEGMENT11' THEN gcc.segment11
            WHEN 'SEGMENT12' THEN gcc.segment12
            WHEN 'SEGMENT13' THEN gcc.segment13
            WHEN 'SEGMENT14' THEN gcc.segment14
            WHEN 'SEGMENT15' THEN gcc.segment15
            WHEN 'SEGMENT16' THEN gcc.segment16
            WHEN 'SEGMENT17' THEN gcc.segment17
            WHEN 'SEGMENT18' THEN gcc.segment18
            WHEN 'SEGMENT19' THEN gcc.segment19
            WHEN 'SEGMENT20' THEN gcc.segment20
            WHEN 'SEGMENT21' THEN gcc.segment21
            WHEN 'SEGMENT22' THEN gcc.segment22
            WHEN 'SEGMENT23' THEN gcc.segment23
            WHEN 'SEGMENT24' THEN gcc.segment24
            WHEN 'SEGMENT25' THEN gcc.segment25
            WHEN 'SEGMENT26' THEN gcc.segment26
            WHEN 'SEGMENT27' THEN gcc.segment27
            WHEN 'SEGMENT28' THEN gcc.segment28
            WHEN 'SEGMENT29' THEN gcc.segment29
            WHEN 'SEGMENT30' THEN gcc.segment30
        END account_value
      FROM ledger_scope ls
      JOIN gl_code_combinations gcc
        ON gcc.chart_of_accounts_id = ls.chart_of_accounts_id
     WHERE gcc.summary_flag = 'N'
       AND (:p_code_combination_id IS NULL OR gcc.code_combination_id = :p_code_combination_id)
       AND CASE ls.account_column
            WHEN 'SEGMENT1' THEN gcc.segment1
            WHEN 'SEGMENT2' THEN gcc.segment2
            WHEN 'SEGMENT3' THEN gcc.segment3
            WHEN 'SEGMENT4' THEN gcc.segment4
            WHEN 'SEGMENT5' THEN gcc.segment5
            WHEN 'SEGMENT6' THEN gcc.segment6
            WHEN 'SEGMENT7' THEN gcc.segment7
            WHEN 'SEGMENT8' THEN gcc.segment8
            WHEN 'SEGMENT9' THEN gcc.segment9
            WHEN 'SEGMENT10' THEN gcc.segment10
            WHEN 'SEGMENT11' THEN gcc.segment11
            WHEN 'SEGMENT12' THEN gcc.segment12
            WHEN 'SEGMENT13' THEN gcc.segment13
            WHEN 'SEGMENT14' THEN gcc.segment14
            WHEN 'SEGMENT15' THEN gcc.segment15
            WHEN 'SEGMENT16' THEN gcc.segment16
            WHEN 'SEGMENT17' THEN gcc.segment17
            WHEN 'SEGMENT18' THEN gcc.segment18
            WHEN 'SEGMENT19' THEN gcc.segment19
            WHEN 'SEGMENT20' THEN gcc.segment20
            WHEN 'SEGMENT21' THEN gcc.segment21
            WHEN 'SEGMENT22' THEN gcc.segment22
            WHEN 'SEGMENT23' THEN gcc.segment23
            WHEN 'SEGMENT24' THEN gcc.segment24
            WHEN 'SEGMENT25' THEN gcc.segment25
            WHEN 'SEGMENT26' THEN gcc.segment26
            WHEN 'SEGMENT27' THEN gcc.segment27
            WHEN 'SEGMENT28' THEN gcc.segment28
            WHEN 'SEGMENT29' THEN gcc.segment29
            WHEN 'SEGMENT30' THEN gcc.segment30
        END = :p_account_value
), posted_lines AS (
    SELECT sa.code_combination_id, gjh.je_batch_id, gjh.je_header_id,
           gjh.name journal_name, gjh.je_source, gjh.je_category,
           gjh.currency_code entered_currency, gjh.posted_date,
           gjl.je_line_num, gjl.effective_date, gjl.description line_description,
           nvl(gjl.entered_dr, 0) entered_dr,
           nvl(gjl.entered_cr, 0) entered_cr,
           nvl(gjl.accounted_dr, 0) accounted_dr,
           nvl(gjl.accounted_cr, 0) accounted_cr
      FROM selected_accounts sa
      JOIN gl_je_lines gjl ON gjl.code_combination_id = sa.code_combination_id
      JOIN gl_je_headers gjh ON gjh.je_header_id = gjl.je_header_id
      JOIN gl_je_batches gjb ON gjb.je_batch_id = gjh.je_batch_id
     WHERE gjh.ledger_id = sa.ledger_id
       AND gjh.period_name = :p_period_name
       AND gjh.status = 'P'
       AND gjh.actual_flag = 'A'
       AND gjh.currency_code <> 'STAT'
       AND nvl(gjb.average_journal_flag, 'N') = 'N'
)
SELECT sa.ledger_id, sa.ledger_name, :p_period_name period_name,
       sa.currency_code ledger_currency,
       sa.account_column, sa.account_value,
       sa.code_combination_id, sa.combination_description, sa.account_type,
       pl.je_batch_id, pl.je_header_id, pl.journal_name,
       pl.je_source, pl.je_category, pl.je_line_num, pl.effective_date,
       pl.posted_date, pl.line_description, pl.entered_currency,
       pl.entered_dr, pl.entered_cr, pl.accounted_dr, pl.accounted_cr,
       pl.accounted_dr - pl.accounted_cr line_net,
       sum(pl.accounted_dr) OVER (PARTITION BY sa.code_combination_id) ccid_period_dr,
       sum(pl.accounted_cr) OVER (PARTITION BY sa.code_combination_id) ccid_period_cr,
       sum(pl.accounted_dr - pl.accounted_cr)
           OVER (PARTITION BY sa.code_combination_id) ccid_period_net,
       sum(pl.accounted_dr) OVER () account_period_dr,
       sum(pl.accounted_cr) OVER () account_period_cr,
       sum(pl.accounted_dr - pl.accounted_cr) OVER () account_period_net
  FROM selected_accounts sa
  JOIN posted_lines pl ON pl.code_combination_id = sa.code_combination_id
 ORDER BY sa.code_combination_id, pl.je_header_id, pl.je_line_num
/
--Query 2: Same ledger, period, natural account and optional CCID.
--Movement = PERIOD_NET_DR - PERIOD_NET_CR.
--Closing = opening + movement, not movement alone.
--Opening is read from GL_BALANCES, not independently rebuilt from history.
--No GL_BALANCES row is reported explicitly, never labelled CUADRA.
WITH ledger_scope AS (
    SELECT gl.ledger_id, gl.name ledger_name, gl.currency_code,
           gl.chart_of_accounts_id,
           (SELECT sav.application_column_name
              FROM fnd_segment_attribute_values sav
             WHERE sav.application_id = 101
               AND sav.id_flex_code = 'GL#'
               AND sav.id_flex_num = gl.chart_of_accounts_id
               AND sav.segment_attribute_type = 'GL_ACCOUNT'
               AND sav.attribute_value = 'Y') account_column
      FROM gl_ledgers gl
     WHERE gl.ledger_id = :p_ledger_id
       AND gl.object_type_code = 'L'
), selected_accounts AS (
    SELECT ls.ledger_id, ls.ledger_name, ls.currency_code,
           ls.account_column, gcc.code_combination_id,
           gcc.description combination_description, gcc.account_type,
           CASE ls.account_column
            WHEN 'SEGMENT1' THEN gcc.segment1
            WHEN 'SEGMENT2' THEN gcc.segment2
            WHEN 'SEGMENT3' THEN gcc.segment3
            WHEN 'SEGMENT4' THEN gcc.segment4
            WHEN 'SEGMENT5' THEN gcc.segment5
            WHEN 'SEGMENT6' THEN gcc.segment6
            WHEN 'SEGMENT7' THEN gcc.segment7
            WHEN 'SEGMENT8' THEN gcc.segment8
            WHEN 'SEGMENT9' THEN gcc.segment9
            WHEN 'SEGMENT10' THEN gcc.segment10
            WHEN 'SEGMENT11' THEN gcc.segment11
            WHEN 'SEGMENT12' THEN gcc.segment12
            WHEN 'SEGMENT13' THEN gcc.segment13
            WHEN 'SEGMENT14' THEN gcc.segment14
            WHEN 'SEGMENT15' THEN gcc.segment15
            WHEN 'SEGMENT16' THEN gcc.segment16
            WHEN 'SEGMENT17' THEN gcc.segment17
            WHEN 'SEGMENT18' THEN gcc.segment18
            WHEN 'SEGMENT19' THEN gcc.segment19
            WHEN 'SEGMENT20' THEN gcc.segment20
            WHEN 'SEGMENT21' THEN gcc.segment21
            WHEN 'SEGMENT22' THEN gcc.segment22
            WHEN 'SEGMENT23' THEN gcc.segment23
            WHEN 'SEGMENT24' THEN gcc.segment24
            WHEN 'SEGMENT25' THEN gcc.segment25
            WHEN 'SEGMENT26' THEN gcc.segment26
            WHEN 'SEGMENT27' THEN gcc.segment27
            WHEN 'SEGMENT28' THEN gcc.segment28
            WHEN 'SEGMENT29' THEN gcc.segment29
            WHEN 'SEGMENT30' THEN gcc.segment30
        END account_value
      FROM ledger_scope ls
      JOIN gl_code_combinations gcc
        ON gcc.chart_of_accounts_id = ls.chart_of_accounts_id
     WHERE gcc.summary_flag = 'N'
       AND (:p_code_combination_id IS NULL OR gcc.code_combination_id = :p_code_combination_id)
       AND CASE ls.account_column
            WHEN 'SEGMENT1' THEN gcc.segment1
            WHEN 'SEGMENT2' THEN gcc.segment2
            WHEN 'SEGMENT3' THEN gcc.segment3
            WHEN 'SEGMENT4' THEN gcc.segment4
            WHEN 'SEGMENT5' THEN gcc.segment5
            WHEN 'SEGMENT6' THEN gcc.segment6
            WHEN 'SEGMENT7' THEN gcc.segment7
            WHEN 'SEGMENT8' THEN gcc.segment8
            WHEN 'SEGMENT9' THEN gcc.segment9
            WHEN 'SEGMENT10' THEN gcc.segment10
            WHEN 'SEGMENT11' THEN gcc.segment11
            WHEN 'SEGMENT12' THEN gcc.segment12
            WHEN 'SEGMENT13' THEN gcc.segment13
            WHEN 'SEGMENT14' THEN gcc.segment14
            WHEN 'SEGMENT15' THEN gcc.segment15
            WHEN 'SEGMENT16' THEN gcc.segment16
            WHEN 'SEGMENT17' THEN gcc.segment17
            WHEN 'SEGMENT18' THEN gcc.segment18
            WHEN 'SEGMENT19' THEN gcc.segment19
            WHEN 'SEGMENT20' THEN gcc.segment20
            WHEN 'SEGMENT21' THEN gcc.segment21
            WHEN 'SEGMENT22' THEN gcc.segment22
            WHEN 'SEGMENT23' THEN gcc.segment23
            WHEN 'SEGMENT24' THEN gcc.segment24
            WHEN 'SEGMENT25' THEN gcc.segment25
            WHEN 'SEGMENT26' THEN gcc.segment26
            WHEN 'SEGMENT27' THEN gcc.segment27
            WHEN 'SEGMENT28' THEN gcc.segment28
            WHEN 'SEGMENT29' THEN gcc.segment29
            WHEN 'SEGMENT30' THEN gcc.segment30
        END = :p_account_value
), posted_lines AS (
    SELECT sa.code_combination_id, gjh.je_batch_id, gjh.je_header_id,
           gjh.name journal_name, gjh.je_source, gjh.je_category,
           gjh.currency_code entered_currency, gjh.posted_date,
           gjl.je_line_num, gjl.effective_date, gjl.description line_description,
           nvl(gjl.entered_dr, 0) entered_dr,
           nvl(gjl.entered_cr, 0) entered_cr,
           nvl(gjl.accounted_dr, 0) accounted_dr,
           nvl(gjl.accounted_cr, 0) accounted_cr
      FROM selected_accounts sa
      JOIN gl_je_lines gjl ON gjl.code_combination_id = sa.code_combination_id
      JOIN gl_je_headers gjh ON gjh.je_header_id = gjl.je_header_id
      JOIN gl_je_batches gjb ON gjb.je_batch_id = gjh.je_batch_id
     WHERE gjh.ledger_id = sa.ledger_id
       AND gjh.period_name = :p_period_name
       AND gjh.status = 'P'
       AND gjh.actual_flag = 'A'
       AND gjh.currency_code <> 'STAT'
       AND nvl(gjb.average_journal_flag, 'N') = 'N'
), line_totals AS (
    SELECT code_combination_id, count(*) line_count,
           sum(accounted_dr) lines_dr, sum(accounted_cr) lines_cr
      FROM posted_lines
     GROUP BY code_combination_id
), balance_totals AS (
    SELECT gb.code_combination_id, count(*) balance_rows,
           sum(nvl(gb.begin_balance_dr, 0)) beginning_dr,
           sum(nvl(gb.begin_balance_cr, 0)) beginning_cr,
           sum(nvl(gb.period_net_dr, 0)) balance_dr,
           sum(nvl(gb.period_net_cr, 0)) balance_cr
      FROM selected_accounts sa
      JOIN gl_balances gb
        ON gb.ledger_id = sa.ledger_id
       AND gb.code_combination_id = sa.code_combination_id
       AND gb.currency_code = sa.currency_code
     WHERE gb.period_name = :p_period_name
       AND gb.actual_flag = 'A'
       AND gb.template_id IS NULL
       AND gb.translated_flag IS NULL
       AND gb.budget_version_id IS NULL
       AND gb.encumbrance_type_id IS NULL
     GROUP BY gb.code_combination_id
), reconciliation AS (
    SELECT sa.*,
           nvl(lt.line_count, 0) line_count,
           nvl(bt.balance_rows, 0) balance_rows,
           nvl(lt.lines_dr, 0) lines_dr,
           nvl(lt.lines_cr, 0) lines_cr,
           nvl(bt.beginning_dr, 0) beginning_dr,
           nvl(bt.beginning_cr, 0) beginning_cr,
           nvl(bt.balance_dr, 0) balance_dr,
           nvl(bt.balance_cr, 0) balance_cr
      FROM selected_accounts sa
      LEFT JOIN line_totals lt ON lt.code_combination_id = sa.code_combination_id
      LEFT JOIN balance_totals bt ON bt.code_combination_id = sa.code_combination_id
)
SELECT r.ledger_id, r.ledger_name, :p_period_name period_name,
       r.currency_code ledger_currency,
       r.account_column, r.account_value, r.code_combination_id,
       r.combination_description, r.account_type,
       r.line_count, r.balance_rows,
       r.lines_dr, r.lines_cr, r.lines_dr - r.lines_cr lines_period_net,
       r.balance_dr, r.balance_cr, r.balance_dr - r.balance_cr balance_period_net,
       r.beginning_dr - r.beginning_cr beginning_balance,
       r.beginning_dr - r.beginning_cr + r.balance_dr - r.balance_cr ending_balance,
       r.beginning_dr - r.beginning_cr + r.lines_dr - r.lines_cr expected_ending_balance,
       r.lines_dr - r.balance_dr difference_dr,
       r.lines_cr - r.balance_cr difference_cr,
       (r.lines_dr - r.lines_cr) - (r.balance_dr - r.balance_cr) difference_net,
       CASE
           WHEN r.balance_rows > 1 THEN 'REVISAR_MULTIPLES_SALDOS'
           WHEN r.balance_rows = 0 AND r.line_count > 0 THEN 'SIN_SALDO_CON_MOVIMIENTOS'
           WHEN r.balance_rows = 0 THEN 'SIN_FILA_GL_BALANCES'
           WHEN abs(r.lines_dr - r.balance_dr) <= abs(nvl(:p_tolerance, 0.01))
            AND abs(r.lines_cr - r.balance_cr) <= abs(nvl(:p_tolerance, 0.01))
               THEN 'CUADRA'
           ELSE 'DIFERENCIA'
       END reconciliation_status,
       sum(r.lines_dr - r.lines_cr) OVER () total_account_movement,
       sum(r.balance_dr - r.balance_cr) OVER () total_balance_movement,
       sum(r.beginning_dr - r.beginning_cr) OVER () total_beginning_balance,
       sum(r.beginning_dr - r.beginning_cr + r.balance_dr - r.balance_cr)
           OVER () total_ending_balance
  FROM reconciliation r
 ORDER BY r.code_combination_id;
