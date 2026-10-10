/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : carga_gl_interface.sql                                      ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 09/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Carga base de dos líneas y pasos de importación estándar.   ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    - Obligatorios:                                                            ║
║      * p_ledger_id (NUMBER)                                                   ║
║      * p_language (VARCHAR2; idioma EBS de la importación)                    ║
║      * p_je_source (VARCHAR2; código interno de origen)                       ║
║      * p_je_category (VARCHAR2; código interno de categoría)                  ║
║      * p_accounting_date (VARCHAR2; YYYY-MM-DD)                               ║
║      * p_period_name (VARCHAR2; período normal abierto)                       ║
║      * p_group_id (NUMBER; entero positivo nuevo y único)                     ║
║      * p_created_by (NUMBER; FND_USER.USER_ID)                                ║
║      * p_debit_ccid, p_credit_ccid (NUMBER; cuentas de detalle distintas)     ║
║      * p_amount (NUMBER; positivo, en moneda del libro)                       ║
║      * p_batch_name, p_journal_name (VARCHAR2)                                ║
║      * p_batch_description, p_journal_description (VARCHAR2; admiten NULL)    ║
║      * p_debit_description, p_credit_description (VARCHAR2; admiten NULL)     ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; nombres de tablas base.         ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin valores predeterminados del contexto de sesión.         ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                   Escribe en GL_INTERFACE al ejecutar el bloque.              ║
║                   Sin COMMIT, importación ni contabilización automáticos.     ║
║                   Mismo valor de balanceo; moneda del libro; período normal.  ║
║                   Plantilla: no es una integración productiva ni idempotente. ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    09/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    10/10/2026: Versión 1.1. Español y sintaxis SQL tradicional.               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

/*
Preparación
- Usar una fuente externa dedicada y cuentas ya existentes (CCID).
- Declarar TODAS las variables de enlace. Las descripciones admiten NULL.
- La moneda se obtiene del libro explícitamente indicado.
- Este ejemplo no cubre divisas, presupuestos, estadísticos, campos
  flexibles descriptivos, períodos de ajuste ni saldos promedio.
- Ejecutar en una sesión de trabajo dedicada, inicialmente en pruebas.
- Conservar el group_id fuera de la interfaz: después de una importación
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
        raise_application_error(-20001, 'Completar variables obligatorias; importe y grupo positivos; CCID distintos.');
    END IF;

    SELECT currency_code, chart_of_accounts_id, bal_seg_column_name,
           enable_average_balances_flag
      INTO l_currency, l_coa_id, l_bal_column, l_average_flag
      FROM gl_ledgers
     WHERE ledger_id = l_ledger_id
       AND object_type_code = 'L'
       AND completion_status_code = 'COMPLETE';
    IF nvl(l_average_flag, 'N') = 'Y' THEN
        raise_application_error(-20002, 'Este ejemplo no admite libros con saldos promedio.');
    END IF;

    SELECT count(*) INTO l_count
      FROM gl_period_statuses
     WHERE application_id = 101 AND ledger_id = l_ledger_id
       AND period_name = l_period_name AND closing_status = 'O'
       AND adjustment_period_flag = 'N'
       AND l_accounting_date >= start_date
       AND l_accounting_date < end_date + 1;
    IF l_count <> 1 THEN
        raise_application_error(-20003, 'La fecha contable debe pertenecer al período normal abierto seleccionado.');
    END IF;

    SELECT count(*) INTO l_count
      FROM fnd_user
     WHERE user_id = l_created_by
       AND (start_date IS NULL OR start_date <= sysdate)
       AND (end_date IS NULL OR end_date > sysdate);
    IF l_count <> 1 THEN
        raise_application_error(-20004, 'CREATED_BY debe identificar un usuario activo de EBS.');
    END IF;

    SELECT je_source_key, user_je_source_name, import_using_key_flag
      INTO l_source_key, l_source_name, l_import_key
      FROM gl_je_sources_tl
     WHERE je_source_name = :p_je_source AND language = l_language;
    SELECT je_category_key, user_je_category_name
      INTO l_category_key, l_category_name
      FROM gl_je_categories_tl
     WHERE je_category_name = :p_je_category AND language = l_language;
    --La importación mediante clave se aplica tanto al origen como a la categoría.
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
        raise_application_error(-20005, 'Se requieren dos CCID contabilizables válidos con el mismo valor de balanceo.');
    END IF;

    SELECT count(*) INTO l_count
      FROM gl_interface
     WHERE ledger_id = l_ledger_id AND group_id = l_group_id;
    IF l_count > 0 THEN
        raise_application_error(-20006, 'El grupo ya existe en la interfaz; revisar antes de reintentar.');
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
    --Transacción pendiente: revisar y ejecutar explícitamente COMMIT o ROLLBACK.
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO gl_demo_load;
        RAISE;
END;
/
--Control previo al COMMIT; repetir tras importar asientos para revisar errores.
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
Lanzamiento estándar (realizar después de revisar las dos filas):
1. Confirmar la carga con COMMIT en esta sesión; o ROLLBACK para descartarla.
2. Con una responsabilidad GL con acceso al libro, abrir la ventana de
   importación de asientos (Asientos > Importar > Ejecutar, según el menú).
3. Elegir libro y origen; seleccionar el grupo específico p_group_id.
4. Para este ejemplo: no crear asientos resumidos ni enviar errores a
   cuentas transitorias; no aplicar fechas parciales ni importar campos
   flexibles descriptivos.
5. Iniciar la importación y conservar el request_id. Revisar el registro,
   la salida y el informe de ejecución de importación de asientos;
   corregir los errores antes de reimportar.
6. Localizar y revisar el lote/asiento creado. Obtener su JE_HEADER_ID.
7. Ejecutar la contabilización estándar tras validar y aprobar el asiento.
   La importación crea asientos; la contabilización actualiza GL_BALANCES.
8. Verificar con asientos_detalle.sql y analisis_cuenta.sql.

No insertar directamente en GL_JE_HEADERS, GL_JE_LINES o GL_BALANCES.
El script no llena GL_INTERFACE_CONTROL: la ventana estándar gestiona
el lanzamiento. No contiene llamadas FND_REQUEST ni contexto de sesión.
La importación estándar realiza la validación completa de EBS (cuentas,
acceso, secuenciación y reglas); los controles anteriores son preliminares.

Referencia:
https://docs.oracle.com/cd/E18727_01/doc.121/e13627/T312864T451269.htm
*/
