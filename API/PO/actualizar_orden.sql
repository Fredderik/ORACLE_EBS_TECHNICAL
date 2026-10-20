/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : actualizar_orden.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Actualizar cantidad, precio o fechas de una orden estándar.
║ Parámetros y transacción: README.md y ejemplos_ejecucion.md de este directorio.
║ Oracle EBS R12.1/R12.2. Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_numero po_headers_all.segment1%TYPE;
    l_revision NUMBER;
    l_cantidad NUMBER;
    l_resultado NUMBER;
    l_fecha DATE;
    l_errores po_api_errors_rec_type;
    l_indice PLS_INTEGER;
    l_prometida DATE;
    l_necesaria DATE;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
BEGIN
    SAVEPOINT inicio_po;
    exigir(:p_user_id > 0 AND :p_resp_id > 0 AND :p_resp_appl_id > 0
            AND :p_org_id > 0, 'Indicar todos los identificadores del contexto EBS.');
    exigir(fnd_global.user_id = :p_user_id AND fnd_global.resp_id = :p_resp_id
            AND fnd_global.resp_appl_id = :p_resp_appl_id,
            'Inicializar el contexto EBS indicado en esta misma sesión antes de ejecutar.');
    mo_global.init('PO');
    exigir(mo_global.check_access(:p_org_id) = 'Y',
            'La responsabilidad no tiene acceso a la unidad operativa.');
    mo_global.set_policy_context('S', :p_org_id);
    exigir(:p_po_header_id > 0 AND :p_revision_num >= 0,
            'Indicar ID de orden y revisión esperada.');
    SELECT pha.segment1, pha.revision_num
      INTO l_numero, l_revision
      FROM po_headers_all pha
     WHERE pha.po_header_id = :p_po_header_id
       AND pha.org_id = :p_org_id
       AND pha.type_lookup_code = 'STANDARD'
       FOR UPDATE NOWAIT;
    exigir(l_revision = :p_revision_num,
            'La revisión actual no coincide; consultar nuevamente antes de continuar.');
    exigir(:p_line_num > 0, 'Indicar número de línea.');
    exigir(:p_shipment_num IS NULL OR :p_shipment_num > 0, 'Número de envío inválido.');
    exigir(:p_new_quantity IS NULL OR :p_new_quantity > 0, 'La cantidad debe ser positiva.');
    exigir(:p_new_price IS NULL OR :p_new_price >= 0, 'El precio no puede ser negativo.');
    l_prometida := TO_DATE(:p_new_promised_date, 'FXYYYY-MM-DD');
    l_necesaria := TO_DATE(:p_new_need_by_date, 'FXYYYY-MM-DD');
    exigir(:p_new_quantity IS NOT NULL OR :p_new_price IS NOT NULL
            OR l_prometida IS NOT NULL OR l_necesaria IS NOT NULL,
            'Indicar al menos un valor nuevo.');
    exigir(:p_shipment_num IS NOT NULL OR (l_prometida IS NULL AND l_necesaria IS NULL),
            'Para cambiar fechas se requiere número de envío.');
    SELECT COUNT(*)
      INTO l_cantidad
      FROM po_lines_all pla
     WHERE pla.po_header_id = :p_po_header_id
       AND pla.org_id = :p_org_id
       AND pla.line_num = :p_line_num;
    exigir(l_cantidad = 1, 'La línea no pertenece a la orden indicada.');
    IF :p_shipment_num IS NOT NULL THEN
        SELECT COUNT(*)
          INTO l_cantidad
          FROM po_lines_all pla, po_line_locations_all plla
         WHERE pla.po_header_id = :p_po_header_id
           AND pla.org_id = :p_org_id
           AND pla.line_num = :p_line_num
           AND plla.po_line_id = pla.po_line_id
           AND plla.po_header_id = pla.po_header_id
           AND plla.org_id = :p_org_id
           AND plla.shipment_num = :p_shipment_num;
        exigir(l_cantidad = 1, 'El envío no pertenece a la línea y orden indicadas.');
    END IF;
    -- Esta función devuelve 1 o 0, no el estado S/E/U de FND_API.
    -- No lanzar aprobaciones aquí: la ruta síncrona puede confirmar internamente.
    l_resultado := po_change_api1_s.update_po(
        x_po_number => l_numero,
        x_release_number => NULL,
        x_revision_number => :p_revision_num,
        x_line_number => :p_line_num,
        x_shipment_number => :p_shipment_num,
        new_quantity => :p_new_quantity,
        new_price => :p_new_price,
        new_promised_date => l_prometida,
        new_need_by_date => l_necesaria,
        launch_approvals_flag => 'N',
        update_source => NULL,
        version => '1.0',
        x_override_date => TO_DATE(:p_override_date, 'FXYYYY-MM-DD'),
        x_api_errors => l_errores,
        p_buyer_name => NULL,
        p_secondary_quantity => NULL,
        p_preferred_grade => NULL,
        p_org_id => :p_org_id);
    IF l_errores IS NOT NULL THEN
        BEGIN
            l_indice := l_errores.message_text.FIRST;
            WHILE l_indice IS NOT NULL LOOP
                DBMS_OUTPUT.PUT_LINE('Mensaje: ' || l_errores.message_text(l_indice));
                l_indice := l_errores.message_text.NEXT(l_indice);
            END LOOP;
        EXCEPTION
            WHEN COLLECTION_IS_NULL THEN NULL;
        END;
    END IF;
    exigir(l_resultado = 1, 'La API rechazó la actualización; revisar los mensajes.');
    DBMS_OUTPUT.PUT_LINE('Orden actualizada: ' || l_numero || '. Revisar si requiere reaprobación.');
    DBMS_OUTPUT.PUT_LINE('Revisar el resultado y decidir COMMIT o ROLLBACK en esta sesión.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_po;
        DBMS_OUTPUT.PUT_LINE('Operación deshecha: ' || SQLERRM);
        RAISE;
END;
/
