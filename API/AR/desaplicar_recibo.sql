/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : desaplicar_recibo.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Desaplicar una aplicación identificada por su ID exacto.
║ NUMBER comunes obligatorios: p_user_id, p_resp_id, p_resp_appl_id, p_org_id.
║ NUMBER: p_receivable_application_id obligatorio.
║ VARCHAR2: p_reversal_gl_date obligatoria. No cancela reclamaciones.
║ Fechas VARCHAR2: YYYY-MM-DD. Declarar todos los binds, también los opcionales.
║ Inicializar contexto en la misma sesión; ver README. Oracle EBS R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_cr_id NUMBER;
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

    l_fecha_gl := TO_DATE(:p_reversal_gl_date, 'FXYYYY-MM-DD');
    exigir(l_fecha_gl IS NOT NULL, 'Indicar fecha contable de desaplicación.');
    SELECT araa.cash_receipt_id INTO l_cr_id
    FROM ar_receivable_applications_all araa
    WHERE araa.receivable_application_id = :p_receivable_application_id
      AND araa.org_id = :p_org_id AND araa.application_type = 'CASH'
      AND araa.status = 'APP' AND araa.display = 'Y';
    ar_receipt_api_pub.unapply(
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje,
        p_org_id => :p_org_id,
        p_cash_receipt_id => l_cr_id,
        p_receivable_application_id => :p_receivable_application_id,
        p_reversal_gl_date => l_fecha_gl,
        p_cancel_claim_flag => 'N');
    revisar_resultado;
    DBMS_OUTPUT.PUT_LINE('Aplicación desaplicada: ' || :p_receivable_application_id);
    DBMS_OUTPUT.PUT_LINE('Cambios pendientes. Revisar resultados y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_ar;
        RAISE;
END;
/
