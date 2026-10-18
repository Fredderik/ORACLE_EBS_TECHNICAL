/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : carga_contactos.sql                                                   ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Alta de contacto para sitio existente.                                ║
║ Parámetros (variables de enlace; declarar también los opcionales):                     ║
║ Obligatorios NUMBER: p_vendor_id, p_vendor_site_id, p_org_id, p_created_by.            ║
║ Obligatorio VARCHAR2: p_last_name.                                                     ║
║ Opcionales VARCHAR2: p_first_name, p_email_address, p_phone.                           ║
║ Oracle EBS R12.1/R12.2. Tablas base y SQL tradicional.                                 ║
║ Pendiente compilación y ejecución en una instancia EBS.                                ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Usa identificadores del proveedor y sitio ya importados, no nombres ambiguos.
-- No crea usuario de portal ni configura cuentas bancarias.
DECLARE
    l_id NUMBER;
    l_cantidad NUMBER;

    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;

BEGIN
    SAVEPOINT carga_ap_contacto;
    exigir(:p_vendor_id IS NOT NULL AND :p_vendor_site_id IS NOT NULL
        AND :p_org_id IS NOT NULL AND TRIM(:p_last_name) IS NOT NULL,
        'Indicar proveedor, sitio, OU y apellido.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_suppliers aps,
         ap_supplier_sites_all assa
    WHERE aps.vendor_id = :p_vendor_id
      AND assa.vendor_id = aps.vendor_id
      AND assa.vendor_site_id = :p_vendor_site_id
      AND assa.org_id = :p_org_id
      AND (aps.start_date_active IS NULL OR aps.start_date_active <= SYSDATE)
      AND (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE)
      AND (assa.inactive_date IS NULL OR assa.inactive_date > SYSDATE);
    exigir(l_cantidad = 1, 'Sitio/proveedor inactivo o combinación proveedor/sitio/OU incorrecta.');

    -- Detección conservadora: personas homónimas requieren revisión manual.
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_supplier_contacts asc_contacto
    WHERE asc_contacto.vendor_site_id = :p_vendor_site_id
      AND UPPER(asc_contacto.last_name) = UPPER(TRIM(:p_last_name))
      AND (UPPER(asc_contacto.first_name) = UPPER(TRIM(:p_first_name))
           OR (asc_contacto.first_name IS NULL AND TRIM(:p_first_name) IS NULL));
    exigir(l_cantidad = 0, 'Ya existe un contacto con ese nombre en el sitio.');
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_sup_site_contact_int assci
    WHERE assci.vendor_site_id = :p_vendor_site_id
      AND assci.org_id = :p_org_id
      AND UPPER(assci.last_name) = UPPER(TRIM(:p_last_name))
      AND (UPPER(assci.first_name) = UPPER(TRIM(:p_first_name))
           OR (assci.first_name IS NULL AND TRIM(:p_first_name) IS NULL));
    exigir(l_cantidad = 0, 'Ya existe ese contacto en la interfaz.');

    SELECT ap_sup_site_contact_int_s.NEXTVAL INTO l_id FROM dual;
    INSERT INTO ap_sup_site_contact_int (
        vendor_contact_interface_id, vendor_id, vendor_site_id, org_id,
        first_name, last_name, email_address, phone, status,
        creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        l_id, :p_vendor_id, :p_vendor_site_id, :p_org_id,
        TRIM(:p_first_name), TRIM(:p_last_name), :p_email_address, :p_phone, 'NEW',
        SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    DBMS_OUTPUT.PUT_LINE('VENDOR_CONTACT_INTERFACE_ID: ' || l_id);
    DBMS_OUTPUT.PUT_LINE('Revisar y decidir COMMIT o ROLLBACK antes de importar.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO carga_ap_contacto;
        RAISE;
END;
/

-- Tras revisar y confirmar, ejecutar Supplier Site Contacts Open Interface Import.
-- Confirmar nombre, alcance y parámetros SRS instalados.
-- Revisar STATUS/REJECT_CODE y el contacto resultante; no reenviar a ciegas.
