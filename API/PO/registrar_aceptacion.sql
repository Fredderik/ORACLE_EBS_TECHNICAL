/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : registrar_aceptacion.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Registrar aceptación o rechazo del proveedor, no aprobación interna.
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
    l_transaccion NUMBER;
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
    exigir(:p_accepted_flag IN ('Y', 'N'), 'Indicar Y para aceptación o N para rechazo.');
    exigir(:p_acceptance_lookup_code IS NOT NULL, 'Indicar código del tipo de aceptación.');
    l_fecha := TO_DATE(:p_action_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL, 'Indicar fecha de aceptación o rechazo.');
    SELECT po_interface_errors_s.NEXTVAL INTO l_transaccion FROM dual;
    DBMS_OUTPUT.PUT_LINE('Identificador para diagnóstico: ' || l_transaccion);
    -- NULL en empleado permite usar el comprador de la orden (AGENT_ID).
    l_resultado := po_change_api1_s.record_acceptance(
        x_po_number => l_numero,
        x_release_number => NULL,
        x_revision_number => :p_revision_num,
        x_action => 'NEW',
        x_action_date => l_fecha,
        x_employee_id => NULL,
        x_accepted_flag => :p_accepted_flag,
        x_acceptance_lookup_code => :p_acceptance_lookup_code,
        x_note => :p_note,
        x_interface_type => 'CHANGEPO',
        x_transaction_id => l_transaccion,
        version => '1.0',
        p_org_id => :p_org_id);
    FOR pie IN (
        SELECT pie.error_message
          FROM po_interface_errors pie
         WHERE pie.interface_type = 'CHANGEPO'
           AND pie.interface_transaction_id = l_transaccion
         ORDER BY pie.processing_date
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Mensaje: ' || pie.error_message);
    END LOOP;
    exigir(l_resultado = 1, 'La API rechazó la aceptación; revisar el identificador de diagnóstico.');
    DBMS_OUTPUT.PUT_LINE('Aceptación/rechazo registrado para la orden: ' || l_numero);
    DBMS_OUTPUT.PUT_LINE('Revisar el resultado y decidir COMMIT o ROLLBACK en esta sesión.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_po;
        DBMS_OUTPUT.PUT_LINE('Operación deshecha: ' || SQLERRM);
        RAISE;
END;
/
