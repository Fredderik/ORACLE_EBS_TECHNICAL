/*
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo: carga_clientes.sql                                                              ║
║ Autor: Freddy E. Aparicio M. | Fecha: 17/10/2026 | Versión: 1.0                          ║
║ Alta de cliente, dirección BILL_TO y perfiles mediante Customer Interface.               ║
║ Parámetros: declarar todos, incluidos los opcionales.                                    ║
║ NUMBER obligatorios: p_org_id, p_created_by.                                             ║
║ VARCHAR2 obligatorios: p_customer_ref, p_address_ref, p_customer_name,                   ║
║   p_profile_class_name, p_address1, p_country.                                           ║
║ VARCHAR2 opcionales: p_customer_number, p_location, p_city, p_state, p_postal_code.      ║
║ Número/location deben ser NULL si su numeración es automática; si es manual, obligatorios. ║
║ R12.1/R12.2. Tablas base; SQL tradicional; pendiente ejecución en EBS.                   ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Crea objetos nuevos; no actualiza clientes existentes ni carga cuentas bancarias.
-- Referencias externas únicas; no se insertan filas directamente en HZ_*.
DECLARE
    l_cantidad NUMBER;
    l_auto_cliente ar_system_parameters_all.auto_customer_numbering%TYPE;
    l_auto_sitio ar_system_parameters_all.auto_site_numbering%TYPE;

    PROCEDURE exigir(p_ok BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_ok IS NULL OR NOT p_ok THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;

BEGIN
    SAVEPOINT carga_ar_cliente;
    exigir(:p_org_id IS NOT NULL AND TRIM(:p_customer_ref) IS NOT NULL
        AND TRIM(:p_address_ref) IS NOT NULL AND TRIM(:p_customer_name) IS NOT NULL
        AND TRIM(:p_profile_class_name) IS NOT NULL AND TRIM(:p_address1) IS NOT NULL
        AND TRIM(:p_country) IS NOT NULL, 'Faltan datos obligatorios del cliente/dirección.');

    SELECT COUNT(*) INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT aspa.auto_customer_numbering, aspa.auto_site_numbering
    INTO l_auto_cliente, l_auto_sitio
    FROM ar_system_parameters_all aspa WHERE aspa.org_id = :p_org_id;
    exigir((l_auto_cliente = 'Y' AND :p_customer_number IS NULL)
         OR (l_auto_cliente = 'N' AND TRIM(:p_customer_number) IS NOT NULL),
         'Número de cliente incompatible con la numeración configurada.');
    exigir((l_auto_sitio = 'Y' AND :p_location IS NULL)
         OR (l_auto_sitio = 'N' AND TRIM(:p_location) IS NOT NULL),
         'Location incompatible con la numeración de sitios configurada.');
    SELECT COUNT(*) INTO l_cantidad FROM hz_cust_profile_classes hcpc
    WHERE hcpc.name = :p_profile_class_name AND hcpc.status = 'A';
    exigir(l_cantidad = 1, 'Clase de perfil inexistente o inactiva.');
    SELECT COUNT(*) INTO l_cantidad FROM fnd_territories ft
    WHERE ft.territory_code = :p_country;
    exigir(l_cantidad = 1, 'País inexistente.');

    SELECT COUNT(*) INTO l_cantidad FROM hz_cust_accounts hca
    WHERE hca.orig_system_reference = :p_customer_ref
       OR (:p_customer_number IS NOT NULL AND hca.account_number = :p_customer_number);
    exigir(l_cantidad = 0, 'La cuenta o referencia externa ya existe.');
    SELECT COUNT(*) INTO l_cantidad FROM ra_customers_interface_all rcia
    WHERE rcia.orig_system_customer_ref = :p_customer_ref;
    exigir(l_cantidad = 0, 'La referencia de cliente ya está en la interfaz.');
    SELECT COUNT(*) INTO l_cantidad FROM ra_customer_profiles_int_all rcpia
    WHERE rcpia.orig_system_customer_ref = :p_customer_ref;
    exigir(l_cantidad = 0, 'La referencia ya tiene perfiles en interfaz.');

    INSERT INTO ra_customers_interface_all (
        orig_system_customer_ref, orig_system_address_ref, org_id,
        insert_update_flag, customer_name, customer_number, customer_status,
        site_use_code, primary_site_use_flag, location,
        address1, city, state, postal_code, country,
        creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        :p_customer_ref, :p_address_ref, :p_org_id,
        'I', :p_customer_name, :p_customer_number, 'A', 'BILL_TO', 'Y', :p_location,
        :p_address1, :p_city, :p_state, :p_postal_code, :p_country,
        SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    -- Un perfil de cuenta y otro para la dirección BILL_TO.
    FOR l_nivel IN 1..2 LOOP
        INSERT INTO ra_customer_profiles_int_all (
            orig_system_customer_ref, orig_system_address_ref, org_id,
            insert_update_flag, customer_profile_class_name,
            creation_date, created_by, last_update_date, last_updated_by
        ) VALUES (
            :p_customer_ref,
            CASE WHEN l_nivel = 2 THEN :p_address_ref ELSE NULL END,
            :p_org_id, 'I', :p_profile_class_name,
            SYSDATE, :p_created_by, SYSDATE, :p_created_by
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Cliente/dirección y perfiles preparados; revisar COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN ROLLBACK TO carga_ar_cliente; RAISE;
END;
/

-- Tras revisar y confirmar: ejecutar Customer Interface desde la responsabilidad
-- autorizada, verificando su alcance y los parámetros instalados.
-- Revisar el Customer Interface Transfer Report y los códigos INTERFACE_STATUS.
-- Obtener CUST_ACCOUNT_ID, CUST_ACCT_SITE_ID y SITE_USE_ID finales antes de facturar.
