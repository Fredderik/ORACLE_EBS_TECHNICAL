/*
╔═══════════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : analisis_cuenta.sql                                             ║
║  Autor          : Freddy E. Aparicio M.                                           ║
║  Fecha creación : 09/10/2026                                                      ║
║  Versión        : 1.2                                                             ║
║  Descripción    : Detalle contabilizado y conciliación con GL_BALANCES.           ║
║                                                                                   ║
║  Parámetros     : Variables de enlace explícitas.                                 ║
║    - Obligatorios:                                                                ║
║      * p_ledger_id (NUMBER)                                                       ║
║      * p_period_name (VARCHAR2; período GL exacto)                                ║
║      * p_account_value (VARCHAR2; cuenta natural con ceros iniciales)             ║
║    - Opcionales (NULL omite el filtro, salvo indicación):                         ║
║      * p_code_combination_id (NUMBER; una combinación)                            ║
║      * p_tolerance (NUMBER; NULL=0.01, solo consulta 2)                           ║
║                                                                                   ║
║  Notas          : Oracle EBS R12 en adelante; nombres de tablas base.             ║
║                   Uniones por igualdad en WHERE; externas con (+).                ║
║                   Sin valores predeterminados del contexto de sesión.             ║
║                   Pendiente validación de ejecución en Oracle EBS.                ║
║                   Asientos reales contabilizados; moneda del libro.               ║
║                   Mismo alcance del saldo, sin filtrar origen, categoría o fecha. ║
║                   GL_ACCOUNT identifica la columna entre SEGMENT1 y SEGMENT30.    ║
║                   Se incluyen combinaciones históricas deshabilitadas.            ║
║                                                                                   ║
║  Actualizaciones:                                                                 ║
║    09/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                      ║
║    10/10/2026: Versión 1.1. Español y sintaxis SQL tradicional.                   ║
║    11/10/2026: Versión 1.2. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════════╝
*/

--Consulta 1: Detalle del período. Los totales se REPITEN; no sumarlos de nuevo.
--Se suman importes ACCOUNTED de todas las monedas ingresadas excepto STAT.
--Sin movimiento, la consulta 1 puede estar vacía; revisar la consulta 2.
WITH ledger_scope AS (
    SELECT gl.ledger_id, gl.name ledger_name, gl.currency_code,
           gl.chart_of_accounts_id,
           (SELECT fsav.application_column_name
              FROM fnd_segment_attribute_values fsav
             WHERE fsav.application_id = 101
               AND fsav.id_flex_code = 'GL#'
               AND fsav.id_flex_num = gl.chart_of_accounts_id
               AND fsav.segment_attribute_type = 'GL_ACCOUNT'
               AND fsav.attribute_value = 'Y') account_column
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
      FROM ledger_scope ls,
           gl_code_combinations gcc
     WHERE gcc.chart_of_accounts_id = ls.chart_of_accounts_id
       AND gcc.summary_flag = 'N'
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
      FROM selected_accounts sa,
           gl_je_lines gjl,
           gl_je_headers gjh,
           gl_je_batches gjb
     WHERE gjl.code_combination_id = sa.code_combination_id
       AND gjh.je_header_id = gjl.je_header_id
       AND gjb.je_batch_id = gjh.je_batch_id
       AND gjh.ledger_id = sa.ledger_id
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
  FROM selected_accounts sa,
       posted_lines pl
 WHERE pl.code_combination_id = sa.code_combination_id
 ORDER BY sa.code_combination_id, pl.je_header_id, pl.je_line_num
/
--Consulta 2: Mismo libro, período, cuenta natural y CCID opcional.
--Movimiento = PERIOD_NET_DR - PERIOD_NET_CR.
--Saldo final = saldo inicial + movimiento.
--El saldo inicial se lee de GL_BALANCES; no se reconstruye desde el histórico.
--La ausencia de fila en GL_BALANCES se indica expresamente; no se marca CUADRA.
WITH ledger_scope AS (
    SELECT gl.ledger_id, gl.name ledger_name, gl.currency_code,
           gl.chart_of_accounts_id,
           (SELECT fsav.application_column_name
              FROM fnd_segment_attribute_values fsav
             WHERE fsav.application_id = 101
               AND fsav.id_flex_code = 'GL#'
               AND fsav.id_flex_num = gl.chart_of_accounts_id
               AND fsav.segment_attribute_type = 'GL_ACCOUNT'
               AND fsav.attribute_value = 'Y') account_column
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
      FROM ledger_scope ls,
           gl_code_combinations gcc
     WHERE gcc.chart_of_accounts_id = ls.chart_of_accounts_id
       AND gcc.summary_flag = 'N'
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
      FROM selected_accounts sa,
           gl_je_lines gjl,
           gl_je_headers gjh,
           gl_je_batches gjb
     WHERE gjl.code_combination_id = sa.code_combination_id
       AND gjh.je_header_id = gjl.je_header_id
       AND gjb.je_batch_id = gjh.je_batch_id
       AND gjh.ledger_id = sa.ledger_id
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
      FROM selected_accounts sa,
           gl_balances gb
     WHERE gb.ledger_id = sa.ledger_id
       AND gb.code_combination_id = sa.code_combination_id
       AND gb.currency_code = sa.currency_code
       AND gb.period_name = :p_period_name
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
      FROM selected_accounts sa,
           line_totals lt,
           balance_totals bt
     WHERE lt.code_combination_id(+) = sa.code_combination_id
       AND bt.code_combination_id(+) = sa.code_combination_id
)
SELECT rec.ledger_id, rec.ledger_name, :p_period_name period_name,
       rec.currency_code ledger_currency,
       rec.account_column, rec.account_value, rec.code_combination_id,
       rec.combination_description, rec.account_type,
       rec.line_count, rec.balance_rows,
       rec.lines_dr, rec.lines_cr, rec.lines_dr - rec.lines_cr lines_period_net,
       rec.balance_dr, rec.balance_cr, rec.balance_dr - rec.balance_cr balance_period_net,
       rec.beginning_dr - rec.beginning_cr beginning_balance,
       rec.beginning_dr - rec.beginning_cr + rec.balance_dr - rec.balance_cr ending_balance,
       rec.beginning_dr - rec.beginning_cr + rec.lines_dr - rec.lines_cr expected_ending_balance,
       rec.lines_dr - rec.balance_dr difference_dr,
       rec.lines_cr - rec.balance_cr difference_cr,
       (rec.lines_dr - rec.lines_cr) - (rec.balance_dr - rec.balance_cr) difference_net,
       CASE
           WHEN rec.balance_rows > 1 THEN 'REVISAR_MULTIPLES_SALDOS'
           WHEN rec.balance_rows = 0 AND rec.line_count > 0 THEN 'SIN_SALDO_CON_MOVIMIENTOS'
           WHEN rec.balance_rows = 0 THEN 'SIN_FILA_GL_BALANCES'
           WHEN abs(rec.lines_dr - rec.balance_dr) <= abs(nvl(:p_tolerance, 0.01))
            AND abs(rec.lines_cr - rec.balance_cr) <= abs(nvl(:p_tolerance, 0.01))
               THEN 'CUADRA'
           ELSE 'DIFERENCIA'
       END reconciliation_status,
       sum(rec.lines_dr - rec.lines_cr) OVER () total_account_movement,
       sum(rec.balance_dr - rec.balance_cr) OVER () total_balance_movement,
       sum(rec.beginning_dr - rec.beginning_cr) OVER () total_beginning_balance,
       sum(rec.beginning_dr - rec.beginning_cr + rec.balance_dr - rec.balance_cr)
           OVER () total_ending_balance
  FROM reconciliation rec
 ORDER BY rec.code_combination_id;
