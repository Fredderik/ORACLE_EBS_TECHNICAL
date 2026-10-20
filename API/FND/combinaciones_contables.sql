/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : combinaciones_contables.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Obtener o crear una combinación contable con FND_FLEX_EXT.
║ Parámetros     : Ver README.md de este directorio.
║ Objetivo       : EBS R12.1/R12.2. Pendiente ejecución en una instancia EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_chart_of_accounts_id NUMBER;
    l_ccid NUMBER;
    l_fecha DATE;
    l_mensaje VARCHAR2(2000);
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
BEGIN
    :p_code_combination_id := NULL;
    SAVEPOINT inicio_combinacion;
    exigir(:p_user_id > 0 AND :p_resp_id > 0 AND :p_resp_appl_id > 0,
           'Indicar usuario, responsabilidad y aplicación de la responsabilidad.');
    exigir(fnd_global.user_id = :p_user_id
           AND fnd_global.resp_id = :p_resp_id
           AND fnd_global.resp_appl_id = :p_resp_appl_id,
           'Inicializar previamente el contexto EBS indicado en esta misma sesión.');
    exigir(:p_ledger_id > 0, 'Indicar el identificador del libro.');
    exigir(:p_segmentos IS NOT NULL, 'Indicar los valores concatenados de los segmentos.');
    exigir(:p_fecha_validacion IS NOT NULL, 'Indicar la fecha con formato AAAA-MM-DD.');
    l_fecha := TO_DATE(:p_fecha_validacion, 'FXYYYY-MM-DD');

    -- El número de estructura es el plan de cuentas, no el identificador del libro.
    SELECT gl.chart_of_accounts_id
      INTO l_chart_of_accounts_id
      FROM gl_ledgers gl
     WHERE gl.ledger_id = :p_ledger_id;

    -- Puede crear una combinación si no existe y la configuración lo permite.
    -- No utilizar esta función como una consulta de solo lectura.
    l_ccid := fnd_flex_ext.get_ccid(
        application_short_name => 'SQLGL',
        key_flex_code          => 'GL#',
        structure_number       => l_chart_of_accounts_id,
        validation_date        => TO_CHAR(l_fecha, 'YYYY/MM/DD HH24:MI:SS'),
        concatenated_segments  => :p_segmentos);

    IF l_ccid IS NULL OR l_ccid <= 0 THEN
        l_mensaje := fnd_flex_ext.get_message;
        DBMS_OUTPUT.PUT_LINE('Mensaje de la API: ' || NVL(l_mensaje, '(sin detalle)'));
        RAISE_APPLICATION_ERROR(-20002, 'No se pudo obtener una combinación contable válida.');
    END IF;

    :p_code_combination_id := l_ccid;
    DBMS_OUTPUT.PUT_LINE('Plan de cuentas: ' || l_chart_of_accounts_id);
    DBMS_OUTPUT.PUT_LINE('Combinación contable (CCID): ' || l_ccid);
    DBMS_OUTPUT.PUT_LINE('La API puede haber reutilizado o creado la combinación.');
    DBMS_OUTPUT.PUT_LINE('Finalizar pronto la transacción mediante COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_combinacion;
        :p_code_combination_id := NULL;
        DBMS_OUTPUT.PUT_LINE('Error al procesar la combinación: ' || SQLERRM);
        RAISE;
END;
/
