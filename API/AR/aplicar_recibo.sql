/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : aplicar_recibo.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Aplicar recibo a una cuota INV del mismo cliente y moneda.
║ NUMBER comunes obligatorios: p_user_id, p_resp_id, p_resp_appl_id, p_org_id.
║ NUMBER: p_cash_receipt_id, p_payment_schedule_id, p_amount_applied (>0).
║ VARCHAR2: p_apply_date, p_gl_date obligatorios. Sin descuentos ni cruce de moneda.
║ Fechas VARCHAR2: YYYY-MM-DD. Declarar todos los binds, también los opcionales.
║ Inicializar contexto en la misma sesión; ver README. Oracle EBS R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_fecha DATE;
    l_fecha_gl DATE;
    l_saldo NUMBER;
    l_estado VARCHAR2(1);
    l_num_mensajes NUMBER;
    l_mensaje VARCHAR2(2000);
    l_cantidad NUMBER;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
    PROCEDURE revisar_resultado IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Estado API: ' || NVL(l_estado, '(sin estado)'));
        IF NVL(l_num_mensajes, 0) > 0 THEN
            FOR l_indice IN 1..l_num_mensajes LOOP
                DBMS_OUTPUT.PUT_LINE('Mensaje: ' || fnd_msg_pub.get(
                    p_msg_index => l_indice, p_encoded => fnd_api.g_false));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE(l_mensaje);
        END IF;
        exigir(l_estado = fnd_api.g_ret_sts_success, 'La API no terminó correctamente.');
    END;
BEGIN
    SAVEPOINT ejemplo_api_ar;
    exigir(:p_user_id >= 0 AND :p_resp_id >= 0 AND :p_resp_appl_id >= 0
        AND :p_org_id > 0, 'Indicar usuario, responsabilidad, aplicación y OU.');
    exigir(fnd_global.user_id = :p_user_id AND fnd_global.resp_id = :p_resp_id
        AND fnd_global.resp_appl_id = :p_resp_appl_id,
        'Inicializar primero el contexto EBS con estos identificadores.');
    mo_global.init('AR');
    exigir(mo_global.check_access(:p_org_id) = 'Y', 'La responsabilidad no tiene acceso a la OU.');
    mo_global.set_policy_context('S', :p_org_id);

    l_fecha := TO_DATE(:p_apply_date, 'FXYYYY-MM-DD');
    l_fecha_gl := TO_DATE(:p_gl_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL AND l_fecha_gl IS NOT NULL AND :p_amount_applied > 0,
        'Indicar fechas e importe positivo.');
    SELECT apsa.amount_due_remaining INTO l_saldo
    FROM ar_cash_receipts_all acra, ar_payment_schedules_all apsa,
         ra_customer_trx_all rcta
    WHERE acra.cash_receipt_id = :p_cash_receipt_id AND acra.org_id = :p_org_id
      AND acra.type = 'CASH' AND acra.status IN ('UNAPP', 'APP')
      AND apsa.payment_schedule_id = :p_payment_schedule_id
      AND apsa.org_id = acra.org_id AND apsa.class = 'INV' AND apsa.status = 'OP'
      AND apsa.customer_id = acra.pay_from_customer
      AND apsa.invoice_currency_code = acra.currency_code
      AND rcta.customer_trx_id = apsa.customer_trx_id AND rcta.org_id = apsa.org_id
      AND rcta.complete_flag = 'Y';
    exigir(:p_amount_applied <= l_saldo, 'El importe supera el saldo de la cuota.');
    ar_receipt_api_pub.apply(
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje,
        p_org_id => :p_org_id,
        p_cash_receipt_id => :p_cash_receipt_id,
        p_applied_payment_schedule_id => :p_payment_schedule_id,
        p_amount_applied => :p_amount_applied,
        p_discount => 0,
        p_apply_date => l_fecha,
        p_apply_gl_date => l_fecha_gl);
    revisar_resultado;
    DBMS_OUTPUT.PUT_LINE('Aplicación realizada; consultar el detalle para obtener RECEIVABLE_APPLICATION_ID.');
    DBMS_OUTPUT.PUT_LINE('Cambios pendientes. Revisar resultados y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_ar;
        RAISE;
END;
/
