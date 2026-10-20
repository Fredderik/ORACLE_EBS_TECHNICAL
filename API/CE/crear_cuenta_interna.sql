/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_cuenta_interna.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Crear cuenta bancaria interna de una entidad legal para AP/AR.
║ Parámetros: README.md y ejemplos_ejecucion.md de este directorio.
║ Objetivo: EBS R12.1/R12.2. Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_id NUMBER;
    l_estado VARCHAR2(1);
    l_num_mensajes NUMBER;
    l_mensaje VARCHAR2(2000);
    l_cantidad NUMBER;
    l_cuenta ce_bank_pub.bankacct_rec_type;
    l_party_id NUMBER;
    l_inicio DATE;
    l_fin DATE;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
    PROCEDURE revisar_resultado IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Estado API: ' || NVL(l_estado, '(sin estado)'));
        FOR l_indice IN 1..NVL(l_num_mensajes, 0) LOOP
            DBMS_OUTPUT.PUT_LINE('Mensaje: ' || fnd_msg_pub.get(
                p_msg_index => l_indice, p_encoded => fnd_api.g_false));
        END LOOP;
        IF NVL(l_num_mensajes, 0) = 0 THEN
            DBMS_OUTPUT.PUT_LINE(l_mensaje);
        END IF;
        exigir(l_estado = fnd_api.g_ret_sts_success, 'La API no terminó correctamente.');
        exigir(l_id > 0, 'La API no devolvió el identificador creado.');
        DBMS_OUTPUT.PUT_LINE('Identificador creado: ' || l_id);
    END;
BEGIN
    SAVEPOINT inicio_ce;
    exigir(:p_user_id > 0 AND :p_resp_id > 0 AND :p_resp_appl_id > 0,
            'Indicar los identificadores del contexto EBS.');
    exigir(fnd_global.user_id = :p_user_id
            AND fnd_global.resp_id = :p_resp_id
            AND fnd_global.resp_appl_id = :p_resp_appl_id,
            'Inicializar el contexto EBS indicado antes de ejecutar, en esta misma sesión.');
    exigir(:p_branch_id > 0 AND :p_legal_entity_id > 0,
            'Indicar sucursal y entidad legal propietaria.');
    exigir(:p_bank_account_name IS NOT NULL AND :p_bank_account_num IS NOT NULL
            AND :p_currency_code IS NOT NULL, 'Indicar nombre, número y moneda de cuenta.');
    exigir(:p_ap_allowed IN ('Y', 'N') AND :p_ar_allowed IN ('Y', 'N')
            AND (:p_ap_allowed = 'Y' OR :p_ar_allowed = 'Y'),
            'Indicar Y/N para AP y AR; habilitar al menos una aplicación.');
    l_inicio := TO_DATE(:p_start_date, 'FXYYYY-MM-DD');
    l_fin := TO_DATE(:p_end_date, 'FXYYYY-MM-DD');
    exigir(l_inicio IS NOT NULL AND (l_fin IS NULL OR l_fin >= l_inicio),
            'Revisar fechas inicial y final.');
    SELECT xep.party_id
      INTO l_party_id
      FROM xle_entity_profiles xep
     WHERE xep.legal_entity_id = :p_legal_entity_id
       AND xep.transacting_entity_flag = 'Y'
       AND (xep.effective_from IS NULL OR xep.effective_from <= l_inicio)
       AND (xep.effective_to IS NULL OR xep.effective_to >= l_inicio);
    SELECT COUNT(*) INTO l_cantidad
      FROM ce_bank_accounts cba
     WHERE cba.bank_branch_id = :p_branch_id
       AND cba.bank_account_num = :p_bank_account_num;
    exigir(l_cantidad = 0, 'Ya existe una cuenta con ese número y sucursal; revisar antes de crear.');
    l_cuenta.branch_id := :p_branch_id;
    -- ACCOUNT_OWNER_ORG_ID representa la entidad legal, no la OU del uso.
    l_cuenta.account_owner_org_id := :p_legal_entity_id;
    l_cuenta.account_owner_party_id := l_party_id;
    l_cuenta.account_classification := 'INTERNAL';
    l_cuenta.bank_account_name := :p_bank_account_name;
    l_cuenta.bank_account_num := :p_bank_account_num;
    l_cuenta.currency := :p_currency_code;
    l_cuenta.acct_type := :p_account_type;
    l_cuenta.iban := :p_iban;
    l_cuenta.check_digits := :p_check_digits;
    l_cuenta.description := :p_description;
    l_cuenta.start_date := l_inicio;
    l_cuenta.end_date := l_fin;
    l_cuenta.ap_use_allowed_flag := :p_ap_allowed;
    l_cuenta.ar_use_allowed_flag := :p_ar_allowed;
    l_cuenta.xtr_use_allowed_flag := 'N';
    l_cuenta.pay_use_allowed_flag := 'N';
    l_cuenta.multi_currency_allowed_flag := 'N';
    l_cuenta.payment_multi_currency_flag := 'N';
    l_cuenta.receipt_multi_currency_flag := 'N';
    l_cuenta.zero_amount_allowed := 'N';
    ce_bank_pub.create_bank_acct(
        p_init_msg_list => fnd_api.g_true,
        p_acct_rec => l_cuenta,
        x_acct_id => l_id,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje);
    revisar_resultado;
    DBMS_OUTPUT.PUT_LINE('Revisar y decidir COMMIT o ROLLBACK manualmente en esta sesión.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_ce;
        DBMS_OUTPUT.PUT_LINE('Operación deshecha: ' || SQLERRM);
        RAISE;
END;
/
