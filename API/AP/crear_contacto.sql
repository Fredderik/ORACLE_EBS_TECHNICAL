/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_contacto.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Crear contacto nuevo asociado a un sitio del proveedor.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_org_id (obligatorios).
║ NUMBER: p_vendor_id, p_vendor_site_id obligatorios.
║ VARCHAR2: p_first_name, p_last_name obligatorios; p_email_address opcional.
║ Inicializar contexto en la misma sesión antes de ejecutar (ver README).
║ Oracle EBS R12.1/R12.2. Pendiente validación nativa.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
    l_contacto ap_vendor_pub_pkg.r_vendor_contact_rec_type;
    l_vendor_contact_id NUMBER;
    l_per_party_id NUMBER;
    l_rel_party_id NUMBER;
    l_rel_id NUMBER;
    l_org_contact_id NUMBER;
    l_party_site_id NUMBER;
    l_org_party_site_id NUMBER;
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

    exigir(:p_vendor_id IS NOT NULL AND :p_vendor_site_id IS NOT NULL
        AND TRIM(:p_first_name) IS NOT NULL AND TRIM(:p_last_name) IS NOT NULL,
        'Indicar proveedor, sitio, nombre y apellido.');
    SELECT assa.party_site_id INTO l_org_party_site_id
    FROM ap_suppliers aps, ap_supplier_sites_all assa
    WHERE aps.vendor_id = :p_vendor_id
      AND aps.enabled_flag = 'Y'
      AND (aps.start_date_active IS NULL OR aps.start_date_active <= SYSDATE)
      AND (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE)
      AND assa.vendor_id = aps.vendor_id
      AND assa.vendor_site_id = :p_vendor_site_id
      AND assa.org_id = :p_org_id
      AND (assa.inactive_date IS NULL OR assa.inactive_date > SYSDATE);
    exigir(l_org_party_site_id IS NOT NULL, 'El sitio no tiene dirección TCA.');

    -- Alta de una persona nueva. No reutiliza ni actualiza contactos existentes.
    l_contacto.vendor_id := :p_vendor_id;
    l_contacto.vendor_site_id := :p_vendor_site_id;
    l_contacto.org_id := :p_org_id;
    l_contacto.org_party_site_id := l_org_party_site_id;
    l_contacto.person_first_name := TRIM(:p_first_name);
    l_contacto.person_last_name := TRIM(:p_last_name);
    l_contacto.email_address := :p_email_address;

    ap_vendor_pub_pkg.create_vendor_contact(
        p_api_version      => 1.0,
        p_init_msg_list    => fnd_api.g_true,
        p_commit           => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status    => l_estado,
        x_msg_count        => l_cantidad_mensajes,
        x_msg_data         => l_mensaje,
        p_vendor_contact_rec => l_contacto,
        x_vendor_contact_id  => l_vendor_contact_id,
        x_per_party_id       => l_per_party_id,
        x_rel_party_id       => l_rel_party_id,
        x_rel_id             => l_rel_id,
        x_org_contact_id     => l_org_contact_id,
        x_party_site_id      => l_party_site_id);
    revisar_resultado;
    exigir(l_vendor_contact_id IS NOT NULL, 'La API no devolvió el contacto.');
    DBMS_OUTPUT.PUT_LINE('VENDOR_CONTACT_ID: ' || l_vendor_contact_id);
    DBMS_OUTPUT.PUT_LINE('PER_PARTY_ID: ' || l_per_party_id || '; REL_PARTY_ID: ' || l_rel_party_id);
    DBMS_OUTPUT.PUT_LINE('REL_ID: ' || l_rel_id || '; ORG_CONTACT_ID: ' || l_org_contact_id);
    DBMS_OUTPUT.PUT_LINE('PARTY_SITE_ID: ' || l_party_site_id);
    DBMS_OUTPUT.PUT_LINE('Alta pendiente de confirmar. Revisar y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO ejemplo_api_ap;
        RAISE;
END;
/
