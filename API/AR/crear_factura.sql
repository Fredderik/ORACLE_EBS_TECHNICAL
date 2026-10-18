/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : crear_factura.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 18/10/2026 | Versión: 1.0
║ Descripción    : Factura INV de una línea en moneda del libro, con AutoAccounting.
║ NUMBER comunes obligatorios: p_user_id, p_resp_id, p_resp_appl_id, p_org_id.
║ NUMBER: p_batch_source_id, p_cust_trx_type_id, p_bill_to_site_use_id,
║ p_term_id, p_amount (>0), obligatorios. p_primary_salesrep_id opcional.
║ VARCHAR2: p_trx_date, p_gl_date, p_description obligatorios; p_trx_number opcional.
║ Fechas VARCHAR2: YYYY-MM-DD. Declarar todos los binds, también los opcionales.
║ Inicializar contexto en la misma sesión; ver README. Oracle EBS R12.1/R12.2.
║ Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 18/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
SET SERVEROUTPUT ON
DECLARE
    l_origen ar_invoice_api_pub.batch_source_rec_type;
    l_cabeceras ar_invoice_api_pub.trx_header_tbl_type;
    l_lineas ar_invoice_api_pub.trx_line_tbl_type;
    l_distribuciones ar_invoice_api_pub.trx_dist_tbl_type;
    l_comisiones ar_invoice_api_pub.trx_salescredits_tbl_type;
    l_contingencias ar_invoice_api_pub.trx_contingencies_tbl_type;
    l_customer_trx_id NUMBER;
    l_cliente NUMBER;
    l_moneda gl_ledgers.currency_code%TYPE;
    l_fecha DATE;
    l_fecha_gl DATE;
    l_estado VARCHAR2(1);
    l_num_mensajes NUMBER;
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
        DBMS_OUTPUT.PUT_LINE('Estado API: ' || NVL(l_estado, '(sin estado)'));
        IF NVL(l_num_mensajes, 0) > 0 THEN
            FOR l_indice IN 1..l_num_mensajes LOOP
                DBMS_OUTPUT.PUT_LINE('Mensaje: ' || fnd_msg_pub.get(
                    p_msg_index => l_indice, p_encoded => fnd_api.g_false));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE(l_mensaje);
        END IF;
        exigir(l_estado = fnd_api.g_ret_sts_success, 'La API no terminó correctamente.');
    END;
BEGIN
    SAVEPOINT ejemplo_api_ar;
    exigir(:p_user_id >= 0 AND :p_resp_id >= 0 AND :p_resp_appl_id >= 0
        AND :p_org_id > 0, 'Indicar usuario, responsabilidad, aplicación y OU.');
    exigir(fnd_global.user_id = :p_user_id AND fnd_global.resp_id = :p_resp_id
        AND fnd_global.resp_appl_id = :p_resp_appl_id,
        'Inicializar primero el contexto EBS con estos identificadores.');
    mo_global.init('AR');
    exigir(mo_global.check_access(:p_org_id) = 'Y', 'La responsabilidad no tiene acceso a la OU.');
    mo_global.set_policy_context('S', :p_org_id);

    l_fecha := TO_DATE(:p_trx_date, 'FXYYYY-MM-DD');
    l_fecha_gl := TO_DATE(:p_gl_date, 'FXYYYY-MM-DD');
    exigir(l_fecha IS NOT NULL AND l_fecha_gl IS NOT NULL AND :p_amount > 0
        AND :p_term_id IS NOT NULL AND TRIM(:p_description) IS NOT NULL,
        'Indicar fechas, importe positivo, términos y descripción.');
    SELECT gl.currency_code INTO l_moneda
    FROM ar_system_parameters_all aspa, gl_ledgers gl
    WHERE aspa.org_id = :p_org_id AND gl.ledger_id = aspa.set_of_books_id;
    SELECT hcasa.cust_account_id INTO l_cliente
    FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa, hz_cust_accounts hca
    WHERE hcsua.site_use_id = :p_bill_to_site_use_id
      AND hcsua.org_id = :p_org_id AND hcsua.site_use_code = 'BILL_TO'
      AND hcsua.status = 'A'
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
      AND hcasa.org_id = hcsua.org_id AND hcasa.status = 'A'
      AND hca.cust_account_id = hcasa.cust_account_id AND hca.status = 'A';

    SELECT COUNT(*) INTO l_cantidad FROM ra_batch_sources_all rbsa
    WHERE rbsa.batch_source_id = :p_batch_source_id AND rbsa.org_id = :p_org_id
      AND rbsa.batch_source_type = 'INV' AND rbsa.status = 'A'
      AND (rbsa.start_date IS NULL OR rbsa.start_date <= l_fecha)
      AND (rbsa.end_date IS NULL OR rbsa.end_date >= l_fecha);
    exigir(l_cantidad = 1, 'La API requiere un origen Manual activo de la OU.');
    SELECT COUNT(*) INTO l_cantidad FROM ra_cust_trx_types_all rctta
    WHERE rctta.cust_trx_type_id = :p_cust_trx_type_id AND rctta.org_id = :p_org_id
      AND rctta.type = 'INV' AND rctta.status = 'A';
    exigir(l_cantidad = 1, 'Tipo INV inexistente o inactivo en la OU.');
    -- No borrar errores de llamadas previas ni mezclar diagnósticos.
    SELECT COUNT(*) INTO l_cantidad FROM ar_trx_errors_gt ateg;
    exigir(l_cantidad = 0, 'Hay errores temporales previos; revisar y usar una sesión nueva.');

    l_origen.batch_source_id := :p_batch_source_id;
    l_origen.default_date := l_fecha;
    -- Identificadores locales para relacionar colecciones; no son IDs finales.
    l_cabeceras(1).trx_header_id := 1;
    l_cabeceras(1).org_id := :p_org_id;
    l_cabeceras(1).trx_number := :p_trx_number;
    l_cabeceras(1).trx_date := l_fecha;
    l_cabeceras(1).gl_date := l_fecha_gl;
    l_cabeceras(1).trx_currency := l_moneda;
    l_cabeceras(1).cust_trx_type_id := :p_cust_trx_type_id;
    l_cabeceras(1).bill_to_customer_id := l_cliente;
    l_cabeceras(1).bill_to_site_use_id := :p_bill_to_site_use_id;
    l_cabeceras(1).term_id := :p_term_id;
    l_cabeceras(1).primary_salesrep_id := :p_primary_salesrep_id;
    l_lineas(1).trx_header_id := 1;
    l_lineas(1).trx_line_id := 1;
    l_lineas(1).line_number := 1;
    l_lineas(1).line_type := 'LINE';
    l_lineas(1).description := :p_description;
    l_lineas(1).quantity_invoiced := 1;
    l_lineas(1).unit_selling_price := :p_amount;

    ar_invoice_api_pub.create_single_invoice(
        p_api_version => 1.0,
        p_init_msg_list => fnd_api.g_true,
        p_commit => fnd_api.g_false,
        p_batch_source_rec => l_origen,
        p_trx_header_tbl => l_cabeceras,
        p_trx_lines_tbl => l_lineas,
        p_trx_dist_tbl => l_distribuciones,
        p_trx_salescredits_tbl => l_comisiones,
        p_trx_contingencies_tbl => l_contingencias,
        x_customer_trx_id => l_customer_trx_id,
        x_return_status => l_estado,
        x_msg_count => l_num_mensajes,
        x_msg_data => l_mensaje);
    -- Imprimir antes de revertir: la tabla temporal pertenece a esta sesión.
    FOR ateg IN (SELECT ateg.error_message, ateg.invalid_value
                FROM ar_trx_errors_gt ateg) LOOP
        DBMS_OUTPUT.PUT_LINE('Validación factura: ' || ateg.error_message
                            || '; valor: ' || ateg.invalid_value);
    END LOOP;
    SELECT COUNT(*) INTO l_cantidad FROM ar_trx_errors_gt ateg;
    revisar_resultado;
    exigir(l_cantidad = 0 AND l_customer_trx_id IS NOT NULL,
           'Factura no creada correctamente; revisar errores temporales.');
    DBMS_OUTPUT.PUT_LINE('CUSTOMER_TRX_ID: ' || l_customer_trx_id);
    DBMS_OUTPUT.PUT_LINE('Cambios pendientes. Revisar resultados y decidir COMMIT o ROLLBACK.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK TO ejemplo_api_ar;
        RAISE;
END;
/
