/*
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo: carga_autoinvoice.sql                                                           ║
║ Autor: Freddy E. Aparicio M. | Fecha: 17/10/2026 | Versión: 1.0                          ║
║ Carga una factura INV de una línea, con numeración manual y AutoAccounting.              ║
║ Parámetros: declarar todos, incluidos los opcionales.                                    ║
║ NUMBER obligatorios: p_org_id, p_bill_to_site_use_id, p_cust_trx_type_id,                ║
║   p_term_id, p_amount (>0), p_created_by.                                                ║
║ VARCHAR2 obligatorios: p_batch_source_name, p_trx_number, p_context,                     ║
║   p_document_ref, p_line_ref, p_description, p_trx_date, p_gl_date.                      ║
║ Fechas: YYYY-MM-DD. Contexto propio con ATTRIBUTE1=documento y ATTRIBUTE2=línea.         ║
║ R12.1/R12.2. Tablas base; SQL tradicional; pendiente ejecución en EBS.                   ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Sin COMMIT ni envío automático. No insertar en tablas finales de AR.
-- Moneda del libro; una línea LINE, cantidad 1; sin impuestos explícitos ni reglas.
-- AutoAccounting debe estar configurado; ZX puede calcular impuestos.
DECLARE
    l_cantidad NUMBER;
    l_cliente NUMBER;
    l_direccion NUMBER;
    l_libro NUMBER;
    l_moneda gl_ledgers.currency_code%TYPE;
    l_precision NUMBER;
    l_fecha DATE := TO_DATE(:p_trx_date, 'FXYYYY-MM-DD');
    l_fecha_gl DATE := TO_DATE(:p_gl_date, 'FXYYYY-MM-DD');

    PROCEDURE exigir(p_ok BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_ok IS NULL OR NOT p_ok THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;

BEGIN
    SAVEPOINT carga_ar_factura;
    exigir(:p_org_id IS NOT NULL AND :p_amount > 0
        AND l_fecha IS NOT NULL AND l_fecha_gl IS NOT NULL,
        'Indicar OU, importe positivo y fechas.');
    exigir(TRIM(:p_batch_source_name) IS NOT NULL AND TRIM(:p_trx_number) IS NOT NULL
        AND TRIM(:p_context) IS NOT NULL AND TRIM(:p_document_ref) IS NOT NULL
        AND TRIM(:p_line_ref) IS NOT NULL AND TRIM(:p_description) IS NOT NULL,
        'Indicar origen, número, contexto, referencias y descripción.');
    exigir(INSTR(:p_document_ref, CHR(10)) = 0 AND INSTR(:p_document_ref, CHR(13)) = 0
        AND INSTR(:p_line_ref, CHR(10)) = 0 AND INSTR(:p_line_ref, CHR(13)) = 0,
        'Las referencias no pueden contener saltos de línea.');

    SELECT COUNT(*) INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT gl.ledger_id, gl.currency_code, fc.precision
    INTO l_libro, l_moneda, l_precision
    FROM ar_system_parameters_all aspa, gl_ledgers gl, fnd_currencies fc
    WHERE aspa.org_id = :p_org_id
      AND gl.ledger_id = aspa.set_of_books_id
      AND fc.currency_code = gl.currency_code;
    exigir(:p_amount = ROUND(:p_amount, l_precision), 'Importe incompatible con precisión monetaria.');

    SELECT COUNT(*) INTO l_cantidad
    FROM ra_batch_sources_all rbsa
    WHERE rbsa.org_id = :p_org_id
      AND rbsa.name = :p_batch_source_name
      AND rbsa.batch_source_type = 'FOREIGN'
      AND rbsa.status = 'A'
      AND rbsa.auto_trx_numbering_flag = 'N'
      AND rbsa.bill_customer_rule = 'I'
      AND rbsa.bill_address_rule = 'I'
      AND rbsa.cust_trx_type_rule = 'I'
      AND rbsa.term_rule = 'I'
      AND (rbsa.start_date IS NULL OR rbsa.start_date <= l_fecha)
      AND (rbsa.end_date IS NULL OR rbsa.end_date >= l_fecha);
    exigir(l_cantidad = 1, 'Origen requerido: importado, activo, numeración manual y reglas por ID.');

    -- El usuario pasa SITE_USE_ID; la interfaz necesita CUST_ACCT_SITE_ID.
    SELECT hca.cust_account_id, hcasa.cust_acct_site_id
    INTO l_cliente, l_direccion
    FROM hz_cust_accounts hca, hz_cust_acct_sites_all hcasa, hz_cust_site_uses_all hcsua
    WHERE hcsua.site_use_id = :p_bill_to_site_use_id
      AND hcsua.org_id = :p_org_id
      AND hcsua.site_use_code = 'BILL_TO'
      AND hcsua.status = 'A'
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
      AND hcasa.org_id = hcsua.org_id
      AND hcasa.status = 'A'
      AND hca.cust_account_id = hcasa.cust_account_id
      AND hca.status = 'A';

    SELECT COUNT(*) INTO l_cantidad
    FROM ra_cust_trx_types_all rctta
    WHERE rctta.cust_trx_type_id = :p_cust_trx_type_id
      AND rctta.org_id = :p_org_id AND rctta.type = 'INV'
      AND rctta.status = 'A'
      AND (rctta.start_date IS NULL OR rctta.start_date <= l_fecha)
      AND (rctta.end_date IS NULL OR rctta.end_date >= l_fecha);
    exigir(l_cantidad = 1, 'Tipo de transacción INV inexistente, inactivo o de otra OU.');

    SELECT COUNT(*) INTO l_cantidad FROM ra_terms_b rtb
    WHERE rtb.term_id = :p_term_id
      AND (rtb.start_date_active IS NULL OR rtb.start_date_active <= l_fecha)
      AND (rtb.end_date_active IS NULL OR rtb.end_date_active >= l_fecha);
    exigir(l_cantidad = 1, 'Términos de pago inexistentes o fuera de vigencia.');
    SELECT COUNT(*) INTO l_cantidad FROM gl_period_statuses gps
    WHERE gps.application_id = 222 AND gps.set_of_books_id = l_libro
      AND gps.closing_status = 'O' AND gps.adjustment_period_flag = 'N'
      AND l_fecha_gl BETWEEN gps.start_date AND gps.end_date;
    exigir(l_cantidad = 1, 'Se requiere un período AR normal abierto.');

    -- Comprobación conservadora de referencia externa; no garantiza idempotencia.
    SELECT COUNT(*) INTO l_cantidad
    FROM ra_interface_lines_all rila
    WHERE rila.org_id = :p_org_id
      AND rila.interface_line_context = :p_context
      AND rila.interface_line_attribute1 = :p_document_ref
      AND rila.interface_line_attribute2 = :p_line_ref;
    exigir(l_cantidad = 0, 'La referencia ya existe en AutoInvoice.');
    SELECT COUNT(*) INTO l_cantidad
    FROM ra_customer_trx_lines_all rctla
    WHERE rctla.org_id = :p_org_id
      AND rctla.interface_line_context = :p_context
      AND rctla.interface_line_attribute1 = :p_document_ref
      AND rctla.interface_line_attribute2 = :p_line_ref;
    exigir(l_cantidad = 0, 'La referencia ya existe en líneas importadas.');

    INSERT INTO ra_interface_lines_all (
        org_id, batch_source_name, line_type, trx_number, trx_date, gl_date,
        currency_code, conversion_type, conversion_rate,
        cust_trx_type_id, term_id, orig_system_bill_customer_id,
        orig_system_bill_address_id, description, quantity, unit_selling_price, amount,
        interface_line_context, interface_line_attribute1, interface_line_attribute2,
        creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        :p_org_id, :p_batch_source_name, 'LINE', :p_trx_number, l_fecha, l_fecha_gl,
        l_moneda, 'User', 1, :p_cust_trx_type_id, :p_term_id, l_cliente,
        l_direccion, :p_description, 1, :p_amount, :p_amount,
        :p_context, :p_document_ref, :p_line_ref,
        SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    DBMS_OUTPUT.PUT_LINE('Línea preparada. Revisar y decidir COMMIT o ROLLBACK.');
    DBMS_OUTPUT.PUT_LINE('INTERFACE_LINE_ID, INTERFACE_STATUS y REQUEST_ID quedan NULL.');
EXCEPTION
    WHEN OTHERS THEN ROLLBACK TO carga_ar_factura; RAISE;
END;
/

-- Después de confirmar, enviar AutoInvoice Master Program desde la OU correcta.
-- Elegir el origen y los filtros exactos disponibles; revisar parámetros SRS locales.
-- El contexto del flexfield debe estar registrado y la agrupación debe separar
-- documentos. Este ejemplo no incluye vendedores obligatorios ni sales credits.
-- No usarlo sin adaptar si la configuración los exige.
