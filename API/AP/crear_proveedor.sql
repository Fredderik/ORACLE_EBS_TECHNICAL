/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_proveedor.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Crear un proveedor global mediante API pública.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_org_id (obligatorios).
║ VARCHAR2: p_vendor_name obligatorio; p_vendor_num opcional según numeración.
║ Inicializar contexto en la misma sesión antes de ejecutar (ver README).
║ Oracle EBS R12.1/R12.2. Pendiente validación nativa.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
    l_proveedor ap_vendor_pub_pkg.r_vendor_rec_type;
    l_vendor_id NUMBER;
    l_party_id NUMBER;
    l_estado VARCHAR2(1);
    l_cantidad_mensajes NUMBER;
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
        DBMS_OUTPUT.PUT_LINE('Estado de la API: ' || NVL(l_estado, '(sin estado)'));
        IF NVL(l_cantidad_mensajes, 0) > 0 THEN
            FOR l_indice IN 1..l_cantidad_mensajes LOOP
                DBMS_OUTPUT.PUT_LINE('Mensaje ' || l_indice || ': ' ||
                    fnd_msg_pub.get(p_msg_index => l_indice,
                                    p_encoded => fnd_api.g_false));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE(l_mensaje);
        END IF;
        exigir(l_estado = fnd_api.g_ret_sts_success,
               'La API no terminó correctamente. Revisar los mensajes anteriores.');
    END;

BEGIN
    SAVEPOINT ejemplo_api_ap;
    -- El contexto se inicializa antes de cargar el paquete AP en esta sesión.
    exigir(:p_user_id IS NOT NULL AND :p_resp_id IS NOT NULL
        AND :p_resp_appl_id IS NOT NULL AND :p_org_id > 0,
        'Indicar usuario, responsabilidad, aplicación y OU.');
    exigir(fnd_global.user_id = :p_user_id
        AND fnd_global.resp_id = :p_resp_id
        AND fnd_global.resp_appl_id = :p_resp_appl_id,
        'Inicializar primero el contexto EBS con estos identificadores.');
    mo_global.init('SQLAP');
    exigir(mo_global.check_access(:p_org_id) = 'Y',
        'La responsabilidad no tiene acceso a la OU indicada.');
    mo_global.set_policy_context('S', :p_org_id);

    exigir(TRIM(:p_vendor_name) IS NOT NULL, 'Indicar nombre del proveedor.');
    SELECT COUNT(*) INTO l_cantidad
    FROM ap_suppliers aps
    WHERE UPPER(aps.vendor_name) = UPPER(TRIM(:p_vendor_name))
       OR (:p_vendor_num IS NOT NULL AND aps.segment1 = :p_vendor_num);
    exigir(l_cantidad = 0, 'Existe un proveedor con ese nombre o número.');

    l_proveedor.vendor_name := TRIM(:p_vendor_name);
    l_proveedor.segment1 := :p_vendor_num;
    l_proveedor.enabled_flag := 'Y';
    l_proveedor.summary_flag := 'N';

    ap_vendor_pub_pkg.create_vendor(
        p_api_version      => 1.0,
        p_init_msg_list    => fnd_api.g_true,
        p_commit           => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status    => l_estado,
        x_msg_count        => l_cantidad_mensajes,
        x_msg_data         => l_mensaje,
        p_vendor_rec       => l_proveedor,
        x_vendor_id        => l_vendor_id,
        x_party_id         => l_party_id);
    revisar_resultado;
    exigir(l_vendor_id IS NOT NULL AND l_party_id IS NOT NULL,
           'La API no devolvió los identificadores esperados.');
    DBMS_OUTPUT.PUT_LINE('VENDOR_ID: ' || l_vendor_id || '; PARTY_ID: ' || l_party_id);
    DBMS_OUTPUT.PUT_LINE('Alta pendiente de confirmar. Revisar y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO ejemplo_api_ap;
        RAISE;
END;
/
