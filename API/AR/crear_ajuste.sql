/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_ajuste.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Ajuste INVOICE por el saldo total de una cuota de factura.
║ NUMBER comunes obligatorios: p_user_id, p_resp_id, p_resp_appl_id, p_org_id.
║ NUMBER: p_payment_schedule_id, p_receivables_trx_id, p_expected_balance (>0).
║ VARCHAR2: p_apply_date, p_gl_date obligatorios; p_comments opcional.
║ Conserva controles de importe y límites de aprobación del usuario.
║ Fechas VARCHAR2: YYYY-MM-DD. Declarar todos los binds, también los opcionales.
║ Inicializar contexto en la misma sesión; ver README. Oracle EBS R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    -- Tipo exigido por la firma pública; las consultas usan tablas base _ALL.
    l_ajuste ar_adjustments%ROWTYPE;
    l_id NUMBER;
    l_numero VARCHAR2(100);
    l_saldo NUMBER;
    l_fecha DATE;
    l_fecha_gl DATE;
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
    exigir(l_fecha IS NOT NULL AND l_fecha_gl IS NOT NULL AND :p_expected_balance > 0
        AND :p_receivables_trx_id IS NOT NULL, 'Indicar fechas, actividad y saldo esperado.');
    SELECT apsa.amount_due_remaining INTO l_saldo
    FROM ar_payment_schedules_all apsa
    WHERE apsa.payment_schedule_id = :p_payment_schedule_id AND apsa.org_id = :p_org_id
      AND apsa.class = 'INV' AND apsa.status = 'OP';
    exigir(l_saldo = :p_expected_balance,
        'El saldo cambió o no coincide; revisar la cuota antes de ajustar.');
    l_ajuste.type := 'INVOICE';
    l_ajuste.payment_schedule_id := :p_payment_schedule_id;
    l_ajuste.amount := -l_saldo;
    l_ajuste.apply_date := l_fecha;
    l_ajuste.gl_date := l_fecha_gl;
    l_ajuste.receivables_trx_id := :p_receivables_trx_id;
    l_ajuste.created_from := 'API_AR_EJEMPLO';
    l_ajuste.comments := :p_comments;
    ar_adjust_pub.create_adjustment(
        p_api_name => 'AR_ADJUST_PUB',
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit_flag => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        p_msg_count => l_num_mensajes,
        p_msg_data => l_mensaje,
        p_return_status => l_estado,
        p_adj_rec => l_ajuste,
        p_chk_approval_limits => fnd_api.g_true,
        p_check_amount => fnd_api.g_true,
        p_new_adjust_number => l_numero,
        p_new_adjust_id => l_id,
        p_org_id => :p_org_id);
    revisar_resultado;
    exigir(l_id IS NOT NULL, 'La API no devolvió ADJUSTMENT_ID.');
    DBMS_OUTPUT.PUT_LINE('ADJUSTMENT_ID: ' || l_id || '; número: ' || l_numero);
    DBMS_OUTPUT.PUT_LINE('Revisar estado/aprobación del ajuste; el alta no implica aprobación.');
    DBMS_OUTPUT.PUT_LINE('Cambios pendientes. Revisar resultados y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_ar;
        RAISE;
END;
/
