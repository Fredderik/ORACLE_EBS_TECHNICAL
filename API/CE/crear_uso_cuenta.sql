/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_uso_cuenta.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Asignar una cuenta interna a una OU para AP y/o AR.
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
    l_uso ce_bank_pub.bankacct_use_rec_type;
    l_propietario NUMBER;
    l_ap VARCHAR2(1);
    l_ar VARCHAR2(1);
    l_inicio DATE;
    l_fin DATE;
    l_fecha DATE;
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
    exigir(:p_org_id > 0 AND :p_bank_account_id > 0 AND :p_legal_entity_id > 0
            AND :p_ledger_id > 0 AND :p_cash_ccid > 0,
            'Indicar OU, cuenta bancaria, entidad legal, libro y combinación de efectivo.');
    exigir(:p_ap_enabled IN ('Y', 'N') AND :p_ar_enabled IN ('Y', 'N')
            AND (:p_ap_enabled = 'Y' OR :p_ar_enabled = 'Y'),
            'Indicar Y/N para AP y AR; habilitar al menos una aplicación.');
    l_fecha := TO_DATE(:p_validation_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL, 'Indicar fecha de validación.');
    mo_global.init('CE');
    exigir(mo_global.check_access(:p_org_id) = 'Y', 'Sin acceso MO a la unidad operativa.');
    mo_global.set_policy_context('S', :p_org_id);
    SELECT cba.account_owner_org_id, cba.ap_use_allowed_flag,
           cba.ar_use_allowed_flag, cba.start_date, cba.end_date
      INTO l_propietario, l_ap, l_ar, l_inicio, l_fin
      FROM ce_bank_accounts cba
     WHERE cba.bank_account_id = :p_bank_account_id
       AND cba.account_classification = 'INTERNAL'
       FOR UPDATE NOWAIT;
    exigir(l_propietario = :p_legal_entity_id, 'La entidad indicada no es propietaria de la cuenta.');
    exigir((l_inicio IS NULL OR l_inicio <= l_fecha) AND (l_fin IS NULL OR l_fin >= l_fecha),
            'La cuenta no está vigente en la fecha indicada.');
    exigir((:p_ap_enabled = 'N' OR l_ap = 'Y') AND (:p_ar_enabled = 'N' OR l_ar = 'Y'),
            'La cuenta no permite alguna de las aplicaciones solicitadas.');
    -- Validar el libro de la OU sin utilizar HR_OPERATING_UNITS.
    SELECT COUNT(*) INTO l_cantidad
      FROM hr_organization_information hoi
     WHERE hoi.organization_id = :p_org_id
       AND hoi.org_information_context = 'Operating Unit Information'
       AND hoi.org_information3 = TO_CHAR(:p_ledger_id, 'FM99999999999999999999');
    exigir(l_cantidad = 1, 'El libro no coincide con el configurado para la OU.');
    SELECT COUNT(*) INTO l_cantidad
      FROM gl_ledgers gl, gl_code_combinations gcc
     WHERE gl.ledger_id = :p_ledger_id
       AND gcc.chart_of_accounts_id = gl.chart_of_accounts_id
       AND gcc.code_combination_id = :p_cash_ccid
       AND gcc.enabled_flag = 'Y'
       AND gcc.summary_flag = 'N'
       AND gcc.detail_posting_allowed_flag = 'Y'
       AND (gcc.start_date_active IS NULL OR gcc.start_date_active <= l_fecha)
       AND (gcc.end_date_active IS NULL OR gcc.end_date_active >= l_fecha);
    exigir(l_cantidad = 1, 'La combinación de efectivo no es válida para el libro y fecha.');
    SELECT COUNT(*) INTO l_cantidad
      FROM ce_bank_acct_uses_all cbaua
     WHERE cbaua.bank_account_id = :p_bank_account_id
       AND cbaua.org_id = :p_org_id;
    exigir(l_cantidad = 0, 'Ya existe un uso para cuenta y OU, incluso si está inactivo.');
    l_uso.bank_account_id := :p_bank_account_id;
    l_uso.org_type := 'OU';
    l_uso.org_id := :p_org_id;
    l_uso.primary_flag := 'N';
    l_uso.ap_use_enable_flag := :p_ap_enabled;
    l_uso.ar_use_enable_flag := :p_ar_enabled;
    l_uso.pay_use_enable_flag := 'N';
    l_uso.xtr_use_enable_flag := 'N';
    l_uso.asset_code_combination_id := :p_cash_ccid;
    IF :p_ap_enabled = 'Y' THEN
        l_uso.ap_asset_ccid := :p_cash_ccid;
    END IF;
    IF :p_ar_enabled = 'Y' THEN
        l_uso.ar_asset_ccid := :p_cash_ccid;
    END IF;
    l_uso.ap_default_settlement_flag := 'N';
    l_uso.xtr_default_settlement_flag := 'N';
    -- LEGAL_ENTITY_ID del uso se reserva para ORG_TYPE=LE, no se rellena para OU.
    ce_bank_pub.create_bank_acct_use(
        p_init_msg_list => fnd_api.g_true,
        p_acct_use_rec => l_uso,
        x_acct_use_id => l_id,
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
