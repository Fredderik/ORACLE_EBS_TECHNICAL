/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : carga_sitios.sql                                                      ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Alta de sitio de pago para proveedor existente.                       ║
║ Parámetros (variables de enlace; declarar también los opcionales):                     ║
║ Obligatorios NUMBER: p_vendor_id, p_org_id, p_created_by.                              ║
║ Obligatorios VARCHAR2: p_vendor_site_code, p_address_line1, p_country.                 ║
║ Opcionales VARCHAR2: p_city, p_state, p_zip.                                           ║
║ Oracle EBS R12.1/R12.2. Tablas base y SQL tradicional.                                 ║
║ Pendiente compilación y ejecución en una instancia EBS.                                ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Proveedor previamente importado. El sitio pertenece a una OU explícita.
-- Plantilla: sitio de pago Y, compras N; sin cuentas bancarias ni impuestos.
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
    SAVEPOINT carga_ap_sitio;
    exigir(:p_org_id IS NOT NULL AND :p_vendor_id IS NOT NULL
        AND TRIM(:p_vendor_site_code) IS NOT NULL
        AND TRIM(:p_address_line1) IS NOT NULL AND TRIM(:p_country) IS NOT NULL,
        'Indicar proveedor, OU, código de sitio, dirección y país.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_system_parameters_all aspa
    WHERE aspa.org_id = :p_org_id;
    exigir(l_cantidad = 1, 'La OU no tiene parámetros de Payables.');
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_suppliers aps
    WHERE aps.vendor_id = :p_vendor_id
      AND (aps.start_date_active IS NULL OR aps.start_date_active <= SYSDATE)
      AND (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE);
    exigir(l_cantidad = 1, 'Proveedor inexistente o inactivo.');
    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_territories ft
    WHERE ft.territory_code = :p_country;
    exigir(l_cantidad = 1, 'Código de país inexistente.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_supplier_sites_all assa
    WHERE assa.vendor_id = :p_vendor_id
      AND assa.org_id = :p_org_id
      AND UPPER(assa.vendor_site_code) = UPPER(TRIM(:p_vendor_site_code));
    exigir(l_cantidad = 0, 'Ya existe ese sitio para el proveedor y OU.');
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_supplier_sites_int assi
    WHERE assi.vendor_id = :p_vendor_id
      AND assi.org_id = :p_org_id
      AND UPPER(assi.vendor_site_code) = UPPER(TRIM(:p_vendor_site_code));
    exigir(l_cantidad = 0, 'Ya existe ese sitio en la interfaz.');

    SELECT ap_supplier_sites_int_s.NEXTVAL INTO l_id FROM dual;
    INSERT INTO ap_supplier_sites_int (
        vendor_site_interface_id, vendor_id, vendor_site_code, org_id,
        address_line1, city, state, zip, country,
        pay_site_flag, purchasing_site_flag, status,
        creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        l_id, :p_vendor_id, TRIM(:p_vendor_site_code), :p_org_id,
        :p_address_line1, :p_city, :p_state, :p_zip, :p_country,
        'Y', 'N', 'NEW', SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    DBMS_OUTPUT.PUT_LINE('VENDOR_SITE_INTERFACE_ID: ' || l_id);
    DBMS_OUTPUT.PUT_LINE('Revisar y decidir COMMIT o ROLLBACK antes de importar.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO carga_ap_sitio;
        RAISE;
END;
/

-- Tras revisar y confirmar, ejecutar Supplier Sites Open Interface Import
-- con responsabilidad y OU correctas. Revisar alcance y parámetros instalados.
-- El importador valida la dirección según el país y aplica valores de configuración.
-- Obtener VENDOR_SITE_ID en AP_SUPPLIER_SITES_ALL antes de cargar contactos.
