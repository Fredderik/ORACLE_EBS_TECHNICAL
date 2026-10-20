/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : cancelar_documento.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Cancelar cabecera, línea o envío de una orden estándar; la API confirma.
║ Parámetros y transacción: README.md y ejemplos_ejecucion.md de este directorio.
║ Oracle EBS R12.1/R12.2. Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
-- Esta operación usa p_commit=TRUE según el contrato público de Oracle.
-- Ejecutar en una sesión exclusiva sin cambios pendientes. No es una simulación.
SET SERVEROUTPUT ON
DECLARE
    l_numero po_headers_all.segment1%TYPE;
    l_revision NUMBER;
    l_cantidad NUMBER;
    l_resultado NUMBER;
    l_fecha DATE;
    l_estado VARCHAR2(1);
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
BEGIN
    exigir(:p_user_id > 0 AND :p_resp_id > 0 AND :p_resp_appl_id > 0
            AND :p_org_id > 0, 'Indicar todos los identificadores del contexto EBS.');
    exigir(fnd_global.user_id = :p_user_id AND fnd_global.resp_id = :p_resp_id
            AND fnd_global.resp_appl_id = :p_resp_appl_id,
            'Inicializar el contexto EBS indicado en esta misma sesión antes de ejecutar.');
    mo_global.init('PO');
    exigir(mo_global.check_access(:p_org_id) = 'Y',
            'La responsabilidad no tiene acceso a la unidad operativa.');
    mo_global.set_policy_context('S', :p_org_id);
    exigir(:p_confirmar_cancelacion = 'SI',
            'La cancelación confirma cambios. Leer README y asignar SI para ejecutarla.');
    exigir(:p_nivel IN ('CABECERA', 'LINEA', 'ENVIO'), 'Nivel de cancelación inválido.');
    exigir(
        (:p_nivel = 'CABECERA' AND :p_po_line_id IS NULL AND :p_line_location_id IS NULL)
        OR (:p_nivel = 'LINEA' AND :p_po_line_id IS NOT NULL AND :p_line_location_id IS NULL)
        OR (:p_nivel = 'ENVIO' AND :p_po_line_id IS NOT NULL AND :p_line_location_id IS NOT NULL),
        'Los identificadores no corresponden al nivel de cancelación solicitado.');
    exigir(:p_cancel_reqs_flag IN ('Y', 'N') AND :p_use_gldate IN ('Y', 'N'),
            'Indicar Y/N para cancelar requisiciones y usar fecha contable.');
    exigir(:p_cancel_reason IS NOT NULL, 'Indicar motivo de cancelación.');
    l_fecha := TO_DATE(:p_action_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL, 'Indicar fecha de cancelación.');
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
    IF :p_po_line_id IS NOT NULL THEN
        SELECT COUNT(*) INTO l_cantidad
          FROM po_lines_all pla
         WHERE pla.po_header_id = :p_po_header_id
           AND pla.po_line_id = :p_po_line_id
           AND pla.org_id = :p_org_id;
        exigir(l_cantidad = 1, 'La línea no pertenece a la orden indicada.');
    END IF;
    IF :p_line_location_id IS NOT NULL THEN
        SELECT COUNT(*) INTO l_cantidad
          FROM po_line_locations_all plla
         WHERE plla.po_header_id = :p_po_header_id
           AND plla.po_line_id = :p_po_line_id
           AND plla.line_location_id = :p_line_location_id
           AND plla.org_id = :p_org_id;
        exigir(l_cantidad = 1, 'El envío no pertenece a la línea y orden indicadas.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Cancelando ' || :p_nivel || ' de orden ' || l_numero);
    po_document_control_pub.control_document(
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit => fnd_api.g_true,
        x_return_status => l_estado,
        p_doc_type => 'PO',
        p_doc_subtype => 'STANDARD',
        p_doc_id => :p_po_header_id,
        p_doc_num => NULL,
        p_release_id => NULL,
        p_release_num => NULL,
        p_doc_line_id => :p_po_line_id,
        p_doc_line_num => NULL,
        p_doc_line_loc_id => :p_line_location_id,
        p_doc_shipment_num => NULL,
        p_action => 'CANCEL',
        p_action_date => l_fecha,
        p_cancel_reason => :p_cancel_reason,
        p_cancel_reqs_flag => :p_cancel_reqs_flag,
        p_print_flag => 'N',
        p_note_to_vendor => :p_note,
        p_use_gldate => :p_use_gldate,
        p_org_id => :p_org_id);
    FOR l_indice IN 1..fnd_msg_pub.count_msg LOOP
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || fnd_msg_pub.get(
            p_msg_index => l_indice, p_encoded => fnd_api.g_false));
    END LOOP;
    exigir(l_estado = fnd_api.g_ret_sts_success, 'La API no devolvió éxito; revisar el documento.');
    DBMS_OUTPUT.PUT_LINE('Cancelación confirmada por la API. Un ROLLBACK posterior no la deshace.');
EXCEPTION
    WHEN OTHERS THEN
        -- Libera bloqueos si siguen pendientes; no revierte un COMMIT de la API.
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Consultar el estado final del documento.');
        RAISE;
END;
/
