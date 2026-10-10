/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║  File Name      : carga_gl_interface.sql                                           ║
║  Author         : Freddy E. Aparicio M.                                            ║
║  Creation Date  : 09/10/2026                                                       ║
║  Version        : 1.0                                                              ║
║  Description    : Base two-line journal load and standard import steps.            ║
║                                                                                    ║
║  Parameters     : Explicit bind variables.                                         ║
║    - Required:                                                                     ║
║      * p_ledger_id (NUMBER)                                                        ║
║      * p_language (VARCHAR2; EBS code matching import language)                    ║
║      * p_je_source (VARCHAR2; internal source code)                                ║
║      * p_je_category (VARCHAR2; internal category code)                            ║
║      * p_accounting_date (VARCHAR2; YYYY-MM-DD)                                    ║
║      * p_period_name (VARCHAR2; explicit normal open period)                       ║
║      * p_group_id (NUMBER; new unique positive integer)                            ║
║      * p_created_by (NUMBER; FND_USER.USER_ID)                                     ║
║      * p_debit_ccid, p_credit_ccid (NUMBER; distinct detail accounts)              ║
║      * p_amount (NUMBER; positive, ledger currency)                                ║
║      * p_batch_name, p_journal_name (VARCHAR2)                                     ║
║      * p_batch_description, p_journal_description (VARCHAR2)                       ║
║      * p_debit_description, p_credit_description (VARCHAR2)                        ║
║                                                                                    ║
║  Notes          : Oracle EBS R12 onwards; base table names.                        ║
║                   No runtime certification on an EBS instance.                     ║
║                   Writes GL_INTERFACE only when YOU execute the block.             ║
║                   No COMMIT, import request or posting is automatic.               ║
║                   Actuals, ledger currency, ordinary period, same balancing value. ║
║                   Not a production integration or an idempotent loader.            ║
║                                                                                    ║
║  Updates        :                                                                  ║
║    - 09/10/2026: Creation - Freddy E. Aparicio M.                                  ║
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

/*
Preparacion
- Usar una fuente externa dedicada y cuentas ya existentes (CCID).
- Declarar TODOS los binds. Las descripciones pueden quedar NULL.
- La moneda se obtiene del libro explicitamente indicado.
- Este ejemplo no cubre divisas, presupuestos, estadisticos, DFF,
  periodos de ajuste ni configuraciones de saldo promedio.
- Ejecutar en una sesion de trabajo dedicada, inicialmente en pruebas.
- Conservar el group_id fuera de la interfaz: despues de una importacion
  correcta las filas pueden desaparecer. Reejecutar puede duplicar asientos.
*/
DECLARE
    l_ledger_id       gl_ledgers.ledger_id%TYPE := :p_ledger_id;
    l_language        gl_je_sources_tl.language%TYPE := :p_language;
    l_group_id        gl_interface.group_id%TYPE := :p_group_id;
    l_created_by      gl_interface.created_by%TYPE := :p_created_by;
    l_debit_ccid      gl_code_combinations.code_combination_id%TYPE := :p_debit_ccid;
    l_credit_ccid     gl_code_combinations.code_combination_id%TYPE := :p_credit_ccid;
    l_amount          NUMBER := :p_amount;
    l_accounting_date DATE := to_date(:p_accounting_date, 'FXYYYY-MM-DD');
    l_period_name     gl_period_statuses.period_name%TYPE := :p_period_name;
    l_currency        gl_ledgers.currency_code%TYPE;
    l_coa_id          gl_ledgers.chart_of_accounts_id%TYPE;
    l_bal_column      gl_ledgers.bal_seg_column_name%TYPE;
    l_average_flag    gl_ledgers.enable_average_balances_flag%TYPE;
    l_source_value    gl_interface.user_je_source_name%TYPE;
    l_category_value  gl_interface.user_je_category_name%TYPE;
    l_source_key      gl_je_sources_tl.je_source_key%TYPE;
    l_source_name     gl_je_sources_tl.user_je_source_name%TYPE;
    l_category_key   gl_je_categories_tl.je_category_key%TYPE;
    l_category_name  gl_je_categories_tl.user_je_category_name%TYPE;
    l_import_key     gl_je_sources_tl.import_using_key_flag%TYPE;
    l_batch_name     gl_interface.reference1%TYPE := :p_batch_name;
    l_journal_name   gl_interface.reference4%TYPE := :p_journal_name;
    l_count          NUMBER;
    l_distinct_bsv   NUMBER;
BEGIN
    SAVEPOINT gl_demo_load;
    IF l_ledger_id IS NULL OR l_language IS NULL
       OR l_accounting_date IS NULL OR l_period_name IS NULL
       OR l_created_by IS NULL OR l_batch_name IS NULL OR l_journal_name IS NULL
       OR l_debit_ccid IS NULL OR l_credit_ccid IS NULL
       OR l_debit_ccid = l_credit_ccid
       OR l_amount IS NULL OR l_amount <= 0
       OR l_group_id IS NULL OR l_group_id <= 0 OR l_group_id <> trunc(l_group_id)
    THEN
        raise_application_error(-20001, 'Complete required binds; amount/group positive; distinct CCIDs.');
    END IF;

    SELECT currency_code, chart_of_accounts_id, bal_seg_column_name,
           enable_average_balances_flag
      INTO l_currency, l_coa_id, l_bal_column, l_average_flag
      FROM gl_ledgers
     WHERE ledger_id = l_ledger_id
       AND object_type_code = 'L'
       AND completion_status_code = 'COMPLETE';
    IF nvl(l_average_flag, 'N') = 'Y' THEN
        raise_application_error(-20002, 'Average-balance ledgers are outside this example.');
    END IF;

    SELECT count(*) INTO l_count
      FROM gl_period_statuses
     WHERE application_id = 101 AND ledger_id = l_ledger_id
       AND period_name = l_period_name AND closing_status = 'O'
       AND adjustment_period_flag = 'N'
       AND l_accounting_date >= start_date
       AND l_accounting_date < end_date + 1;
    IF l_count <> 1 THEN
        raise_application_error(-20003, 'Accounting date must belong to the selected open normal period.');
    END IF;

    SELECT count(*) INTO l_count
      FROM fnd_user
     WHERE user_id = l_created_by
       AND (start_date IS NULL OR start_date <= sysdate)
       AND (end_date IS NULL OR end_date > sysdate);
    IF l_count <> 1 THEN
        raise_application_error(-20004, 'CREATED_BY must identify an active EBS user.');
    END IF;

    SELECT je_source_key, user_je_source_name, import_using_key_flag
      INTO l_source_key, l_source_name, l_import_key
      FROM gl_je_sources_tl
     WHERE je_source_name = :p_je_source AND language = l_language;
    SELECT je_category_key, user_je_category_name
      INTO l_category_key, l_category_name
      FROM gl_je_categories_tl
     WHERE je_category_name = :p_je_category AND language = l_language;
    --Import Using Key applies to BOTH source and category.
    IF l_import_key = 'Y' THEN
        l_source_value := l_source_key;
        l_category_value := l_category_key;
    ELSE
        l_source_value := l_source_name;
        l_category_value := l_category_name;
    END IF;

    SELECT count(balancing_value), count(DISTINCT balancing_value)
      INTO l_count, l_distinct_bsv
      FROM (
        SELECT CASE l_bal_column
                   WHEN 'SEGMENT1' THEN cc.segment1
                   WHEN 'SEGMENT2' THEN cc.segment2
                   WHEN 'SEGMENT3' THEN cc.segment3
                   WHEN 'SEGMENT4' THEN cc.segment4
                   WHEN 'SEGMENT5' THEN cc.segment5
                   WHEN 'SEGMENT6' THEN cc.segment6
                   WHEN 'SEGMENT7' THEN cc.segment7
                   WHEN 'SEGMENT8' THEN cc.segment8
                   WHEN 'SEGMENT9' THEN cc.segment9
                   WHEN 'SEGMENT10' THEN cc.segment10
                   WHEN 'SEGMENT11' THEN cc.segment11
                   WHEN 'SEGMENT12' THEN cc.segment12
                   WHEN 'SEGMENT13' THEN cc.segment13
                   WHEN 'SEGMENT14' THEN cc.segment14
                   WHEN 'SEGMENT15' THEN cc.segment15
                   WHEN 'SEGMENT16' THEN cc.segment16
                   WHEN 'SEGMENT17' THEN cc.segment17
                   WHEN 'SEGMENT18' THEN cc.segment18
                   WHEN 'SEGMENT19' THEN cc.segment19
                   WHEN 'SEGMENT20' THEN cc.segment20
                   WHEN 'SEGMENT21' THEN cc.segment21
                   WHEN 'SEGMENT22' THEN cc.segment22
                   WHEN 'SEGMENT23' THEN cc.segment23
                   WHEN 'SEGMENT24' THEN cc.segment24
                   WHEN 'SEGMENT25' THEN cc.segment25
                   WHEN 'SEGMENT26' THEN cc.segment26
                   WHEN 'SEGMENT27' THEN cc.segment27
                   WHEN 'SEGMENT28' THEN cc.segment28
                   WHEN 'SEGMENT29' THEN cc.segment29
                   WHEN 'SEGMENT30' THEN cc.segment30
               END balancing_value
          FROM gl_code_combinations cc
         WHERE cc.code_combination_id IN (l_debit_ccid, l_credit_ccid)
           AND cc.chart_of_accounts_id = l_coa_id
           AND cc.enabled_flag = 'Y' AND cc.summary_flag = 'N'
           AND cc.detail_posting_allowed_flag = 'Y'
           AND (cc.start_date_active IS NULL OR cc.start_date_active <= l_accounting_date)
           AND (cc.end_date_active IS NULL OR cc.end_date_active >= l_accounting_date)
      );
    IF l_count <> 2 OR l_distinct_bsv <> 1 THEN
        raise_application_error(-20005, 'Two valid posting CCIDs with the same balancing value are required.');
    END IF;

    SELECT count(*) INTO l_count
      FROM gl_interface
     WHERE ledger_id = l_ledger_id AND group_id = l_group_id;
    IF l_count > 0 THEN
        raise_application_error(-20006, 'Group already staged; inspect before retrying.');
    END IF;

    INSERT INTO gl_interface (
        status, ledger_id, user_je_source_name, user_je_category_name,
        accounting_date, currency_code, date_created, created_by, actual_flag,
        group_id, code_combination_id, entered_dr, entered_cr,
        reference1, reference2, reference4, reference5, reference10
    ) VALUES (
        'NEW', l_ledger_id, l_source_value, l_category_value,
        l_accounting_date, l_currency, sysdate, l_created_by, 'A',
        l_group_id, l_debit_ccid, l_amount, NULL,
        l_batch_name, :p_batch_description, l_journal_name,
        :p_journal_description, :p_debit_description
    );

    INSERT INTO gl_interface (
        status, ledger_id, user_je_source_name, user_je_category_name,
        accounting_date, currency_code, date_created, created_by, actual_flag,
        group_id, code_combination_id, entered_dr, entered_cr,
        reference1, reference2, reference4, reference5, reference10
    ) VALUES (
        'NEW', l_ledger_id, l_source_value, l_category_value,
        l_accounting_date, l_currency, sysdate, l_created_by, 'A',
        l_group_id, l_credit_ccid, NULL, l_amount,
        l_batch_name, :p_batch_description, l_journal_name,
        :p_journal_description, :p_credit_description
    );
    --Uncommitted: inspect below, then explicitly COMMIT or ROLLBACK.
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO gl_demo_load;
        RAISE;
END;
/
--Control before COMMIT; run again after Journal Import to inspect errors.
SELECT gi.ledger_id, gi.group_id, gi.status, gi.status_description,
       gi.user_je_source_name, gi.user_je_category_name,
       gi.code_combination_id, gi.accounting_date, gi.currency_code,
       gi.entered_dr, gi.entered_cr,
       sum(nvl(gi.entered_dr, 0)) OVER () group_dr,
       sum(nvl(gi.entered_cr, 0)) OVER () group_cr,
       sum(nvl(gi.entered_dr, 0) - nvl(gi.entered_cr, 0)) OVER () group_difference,
       gi.reference1 batch_reference, gi.reference4 journal_reference,
       gi.reference10 line_description, gi.request_id
  FROM gl_interface gi
 WHERE gi.ledger_id = :p_ledger_id
   AND gi.group_id = :p_group_id
 ORDER BY gi.code_combination_id;

/*
Lanzamiento estandar (realizar despues de revisar las dos filas):
1. Confirmar la carga con COMMIT en esta sesion; o ROLLBACK para descartarla.
2. En una responsabilidad GL con acceso al libro, abrir Import Journals
   (habitualmente Journals > Import > Run; depende del menu).
3. Elegir libro y origen; Specific Group ID = p_group_id.
4. Para este ejemplo: Create Summary Journals = No; Post Errors to Suspense
   = No; sin filtro parcial de fechas ni DFF.
5. Pulsar Import y conservar el request_id. Revisar log, salida y
   Journal Import Execution Report; corregir errores antes de reimportar.
6. Localizar y revisar el lote/asiento creado. Obtener su JE_HEADER_ID.
7. Ejecutar el Posting estandar tras las validaciones/aprobaciones del sitio.
   Journal Import crea asientos; GL_BALANCES cambia con Posting.
8. Verificar con asientos_detalle.sql y analisis_cuenta.sql.

No insertar directamente en GL_JE_HEADERS, GL_JE_LINES o GL_BALANCES.
El script no llena GL_INTERFACE_CONTROL: la ventana estandar gestiona
el lanzamiento. No contiene llamadas FND_REQUEST ni contexto de sesion.
La validacion completa de EBS (cuentas, acceso, secuenciacion y reglas)
la realiza Journal Import; las comprobaciones anteriores son preliminares.

Referencia:
https://docs.oracle.com/cd/E18727_01/doc.121/e13627/T312864T451269.htm
*/
