/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_sitio.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026
║ Versión        : 1.0
║ Descripción    : Crear sitio de pago/compras y su dirección.
║ Comunes NUMBER : p_user_id, p_resp_id, p_resp_appl_id, p_org_id (obligatorios).
║ NUMBER: p_vendor_id obligatorio. VARCHAR2: p_vendor_site_code, p_address_line1,
║ p_country, p_pay_site_flag, p_purchasing_site_flag obligatorios (flags Y/N).
║ VARCHAR2 opcionales: p_city, p_state, p_zip; requeridos según país/configuración.
║ Inicializar contexto en la misma sesión antes de ejecutar (ver README).
║ Oracle EBS R12.1/R12.2. Pendiente validación nativa.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

SET SERVEROUTPUT ON
DECLARE
    l_sitio ap_vendor_pub_pkg.r_vendor_site_rec_type;
    l_vendor_site_id NUMBER;
    l_party_site_id NUMBER;
    l_location_id NUMBER;
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

    exigir(:p_vendor_id IS NOT NULL AND TRIM(:p_vendor_site_code) IS NOT NULL
        AND TRIM(:p_address_line1) IS NOT NULL AND TRIM(:p_country) IS NOT NULL,
        'Indicar proveedor, código, dirección y país.');
    exigir(:p_pay_site_flag IN ('Y', 'N') AND :p_purchasing_site_flag IN ('Y', 'N')
        AND (:p_pay_site_flag = 'Y' OR :p_purchasing_site_flag = 'Y'),
        'Indicar flags Y/N y habilitar al menos pago o compras.');
    SELECT COUNT(*) INTO l_cantidad
    FROM ap_suppliers aps
    WHERE aps.vendor_id = :p_vendor_id AND aps.enabled_flag = 'Y'
      AND (aps.start_date_active IS NULL OR aps.start_date_active <= SYSDATE)
      AND (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE);
    exigir(l_cantidad = 1, 'Proveedor inexistente o inactivo.');
    SELECT COUNT(*) INTO l_cantidad
    FROM ap_supplier_sites_all assa
    WHERE assa.vendor_id = :p_vendor_id AND assa.org_id = :p_org_id
      AND UPPER(assa.vendor_site_code) = UPPER(TRIM(:p_vendor_site_code));
    exigir(l_cantidad = 0, 'El código de sitio ya existe para ese proveedor y OU.');

    l_sitio.vendor_id := :p_vendor_id;
    l_sitio.org_id := :p_org_id;
    l_sitio.vendor_site_code := TRIM(:p_vendor_site_code);
    l_sitio.address_line1 := :p_address_line1;
    l_sitio.country := :p_country;
    l_sitio.city := :p_city;
    l_sitio.state := :p_state;
    l_sitio.zip := :p_zip;
    l_sitio.pay_site_flag := :p_pay_site_flag;
    l_sitio.purchasing_site_flag := :p_purchasing_site_flag;

    ap_vendor_pub_pkg.create_vendor_site(
        p_api_version      => 1.0,
        p_init_msg_list    => fnd_api.g_true,
        p_commit           => fnd_api.g_false,
        p_validation_level => fnd_api.g_valid_level_full,
        x_return_status    => l_estado,
        x_msg_count        => l_cantidad_mensajes,
        x_msg_data         => l_mensaje,
        p_vendor_site_rec => l_sitio,
        x_vendor_site_id  => l_vendor_site_id,
        x_party_site_id   => l_party_site_id,
        x_location_id     => l_location_id);
    revisar_resultado;
    exigir(l_vendor_site_id IS NOT NULL, 'La API no devolvió el sitio.');
    DBMS_OUTPUT.PUT_LINE('VENDOR_SITE_ID: ' || l_vendor_site_id);
    DBMS_OUTPUT.PUT_LINE('PARTY_SITE_ID: ' || l_party_site_id || '; LOCATION_ID: ' || l_location_id);
    DBMS_OUTPUT.PUT_LINE('Alta pendiente de confirmar. Revisar y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO ejemplo_api_ap;
        RAISE;
END;
/
