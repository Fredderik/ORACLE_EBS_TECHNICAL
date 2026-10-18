/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : carga_proveedores.sql                                                 ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Alta mínima de un proveedor global.                                   ║
║ Parámetros (variables de enlace; declarar también los opcionales):                     ║
║ Obligatorios: p_vendor_name VARCHAR2; p_created_by NUMBER.                             ║
║ Opcional: p_vendor_num VARCHAR2 (obligatorio si numeración manual).                    ║
║ Oracle EBS R12.1/R12.2. Tablas base y SQL tradicional.                                 ║
║ Pendiente compilación y ejecución en una instancia EBS.                                ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Carga una alta, no una actualización. Proveedores globales: no hay filtro ORG_ID.
-- Los valores predeterminados del importador dependen de su responsabilidad/OU.
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
    SAVEPOINT carga_ap_proveedor;
    exigir(TRIM(:p_vendor_name) IS NOT NULL, 'Indicar el nombre del proveedor.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_suppliers aps
    WHERE UPPER(aps.vendor_name) = UPPER(TRIM(:p_vendor_name))
       OR (:p_vendor_num IS NOT NULL AND aps.segment1 = :p_vendor_num);
    exigir(l_cantidad = 0, 'Ya existe un proveedor con ese nombre o número.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_suppliers_int asi
    WHERE UPPER(asi.vendor_name) = UPPER(TRIM(:p_vendor_name))
       OR (:p_vendor_num IS NOT NULL AND asi.segment1 = :p_vendor_num);
    exigir(l_cantidad = 0, 'Ya existe una fila del proveedor en la interfaz.');

    SELECT ap_suppliers_int_s.NEXTVAL INTO l_id FROM dual;
    INSERT INTO ap_suppliers_int (
        vendor_interface_id, vendor_name, segment1, status,
        creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        l_id, TRIM(:p_vendor_name), :p_vendor_num, 'NEW',
        SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    DBMS_OUTPUT.PUT_LINE('VENDOR_INTERFACE_ID: ' || l_id);
    DBMS_OUTPUT.PUT_LINE('Revisar y decidir COMMIT o ROLLBACK antes de importar.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO carga_ap_proveedor;
        RAISE;
END;
/

-- Tras revisar y confirmar, ejecutar Supplier Open Interface Import.
-- Seleccionar la responsabilidad/OU que proporciona los valores predeterminados.
-- Comprobar en SRS el alcance real: no suponer que filtra por este ID.
-- Consultar STATUS y REJECT_CODE. Obtener el VENDOR_ID creado en AP_SUPPLIERS
-- antes de cargar los sitios. VENDOR_INTERFACE_ID no es VENDOR_ID.
