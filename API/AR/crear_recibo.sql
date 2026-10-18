/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_recibo.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Crear recibo identificado, en moneda del libro.
║ NUMBER comunes obligatorios: p_user_id, p_resp_id, p_resp_appl_id, p_org_id.
║ NUMBER: p_bill_to_site_use_id, p_receipt_method_id, p_bank_acct_use_id,
║ p_amount (>0), obligatorios. VARCHAR2: p_receipt_number, p_receipt_date,
║ p_gl_date obligatorios; p_comments opcional.
║ Fechas VARCHAR2: YYYY-MM-DD. Declarar todos los binds, también los opcionales.
║ Inicializar contexto en la misma sesión; ver README. Oracle EBS R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_cliente NUMBER;
    l_moneda gl_ledgers.currency_code%TYPE;
    l_fecha DATE;
    l_fecha_gl DATE;
    l_cr_id NUMBER;
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

    l_fecha := TO_DATE(:p_receipt_date, 'FXYYYY-MM-DD');
    l_fecha_gl := TO_DATE(:p_gl_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL AND l_fecha_gl IS NOT NULL AND :p_amount > 0
        AND TRIM(:p_receipt_number) IS NOT NULL AND :p_receipt_method_id IS NOT NULL
        AND :p_bank_acct_use_id IS NOT NULL, 'Completar fechas, importe, número, método y uso bancario.');
    SELECT gl.currency_code INTO l_moneda
    FROM ar_system_parameters_all aspa, gl_ledgers gl
    WHERE aspa.org_id = :p_org_id AND gl.ledger_id = aspa.set_of_books_id;
    SELECT hcasa.cust_account_id INTO l_cliente
    FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa, hz_cust_accounts hca
    WHERE hcsua.site_use_id = :p_bill_to_site_use_id
      AND hcsua.org_id = :p_org_id AND hcsua.site_use_code = 'BILL_TO'
      AND hcsua.status = 'A'
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
      AND hcasa.org_id = hcsua.org_id AND hcasa.status = 'A'
      AND hca.cust_account_id = hcasa.cust_account_id AND hca.status = 'A';

    SELECT COUNT(*) INTO l_cantidad FROM ce_bank_acct_uses_all cbaua
    WHERE cbaua.bank_acct_use_id = :p_bank_acct_use_id AND cbaua.org_id = :p_org_id
      AND cbaua.ar_use_enable_flag = 'Y';
    exigir(l_cantidad = 1, 'Uso bancario no habilitado para AR en la OU.');
    SELECT COUNT(*) INTO l_cantidad FROM ar_cash_receipts_all acra
    WHERE acra.org_id = :p_org_id AND acra.receipt_number = :p_receipt_number
      AND acra.pay_from_customer = l_cliente;
    exigir(l_cantidad = 0, 'Ya existe un recibo de ese cliente con el mismo número.');
    ar_receipt_api_pub.create_cash(
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje,
        p_org_id => :p_org_id,
        p_currency_code => l_moneda,
        p_amount => :p_amount,
        p_receipt_number => :p_receipt_number,
        p_receipt_date => l_fecha,
        p_gl_date => l_fecha_gl,
        p_customer_id => l_cliente,
        p_customer_site_use_id => :p_bill_to_site_use_id,
        p_default_site_use => 'N',
        p_receipt_method_id => :p_receipt_method_id,
        p_remittance_bank_account_id => :p_bank_acct_use_id,
        p_comments => :p_comments,
        p_cr_id => l_cr_id);
    revisar_resultado;
    exigir(l_cr_id IS NOT NULL, 'La API no devolvió CASH_RECEIPT_ID.');
    DBMS_OUTPUT.PUT_LINE('CASH_RECEIPT_ID: ' || l_cr_id);
    DBMS_OUTPUT.PUT_LINE('Cambios pendientes. Revisar resultados y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_ar;
        RAISE;
END;
/
