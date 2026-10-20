/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_sucursal.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Crear sucursal bancaria bajo un banco existente.
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
    l_existente NUMBER;
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
    exigir(:p_bank_id > 0 AND :p_branch_name IS NOT NULL,
            'Indicar ID del banco y nombre de sucursal.');
    ce_bank_pub.check_branch_exist(
        p_bank_id => :p_bank_id,
        p_branch_name => :p_branch_name,
        p_branch_number => :p_branch_number,
        x_branch_id => l_existente,
        x_end_date => l_fin);
    exigir(l_existente IS NULL, 'La sucursal ya existe; revisar su ID y vigencia.');
    ce_bank_pub.create_bank_branch(
        p_init_msg_list => fnd_api.g_true,
        p_bank_id => :p_bank_id,
        p_branch_name => :p_branch_name,
        p_branch_number => :p_branch_number,
        p_branch_type => :p_branch_type,
        p_description => :p_description,
        p_bic => :p_bic,
        x_branch_id => l_id,
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
