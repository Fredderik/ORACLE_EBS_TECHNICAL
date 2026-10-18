/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : carga_facturas.sql                                                    ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Factura estándar con una línea ITEM sin conciliación PO.              ║
║ Parámetros (variables de enlace; declarar también los opcionales):                     ║
║ Obligatorios NUMBER: p_org_id, p_vendor_id, p_vendor_site_id,                          ║
║   p_terms_id, p_expense_ccid, p_amount (> 0), p_created_by.                            ║
║ Obligatorios VARCHAR2: p_source, p_group_id, p_invoice_num,                            ║
║   p_invoice_date y p_gl_date (YYYY-MM-DD).                                             ║
║ Opcional VARCHAR2: p_description. Moneda: la del libro de la OU.                       ║
║ Oracle EBS R12.1/R12.2. Tablas base y SQL tradicional.                                 ║
║ Pendiente compilación y ejecución en una instancia EBS.                                ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Escribe solo en las dos tablas de interfaz. Sin COMMIT ni envío automático.
-- No cubre divisas, PO, retenciones, anticipos ni carga explícita de impuestos.
-- La configuración ZX puede calcular impuestos: revisar el resultado importado.
DECLARE
    l_invoice_id NUMBER;
    l_line_id NUMBER;
    l_cantidad NUMBER;
    l_ledger_id NUMBER;
    l_coa_id NUMBER;
    l_moneda gl_ledgers.currency_code%TYPE;
    l_precision NUMBER;
    l_fecha_factura DATE := TO_DATE(:p_invoice_date, 'FXYYYY-MM-DD');
    l_fecha_contable DATE := TO_DATE(:p_gl_date, 'FXYYYY-MM-DD');

    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;

BEGIN
    SAVEPOINT carga_ap_factura;
    exigir(:p_org_id IS NOT NULL AND :p_vendor_id IS NOT NULL
        AND :p_vendor_site_id IS NOT NULL AND :p_terms_id IS NOT NULL
        AND :p_expense_ccid IS NOT NULL, 'Indicar organización, proveedor, sitio, términos y cuenta.');
    exigir(:p_amount > 0 AND l_fecha_factura IS NOT NULL
        AND l_fecha_contable IS NOT NULL, 'Indicar importe positivo y fechas válidas.');
    exigir(TRIM(:p_source) IS NOT NULL AND TRIM(:p_group_id) IS NOT NULL
        AND TRIM(:p_invoice_num) IS NOT NULL, 'Indicar origen, grupo y número de factura.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM fnd_user fu
    WHERE fu.user_id = :p_created_by
      AND (fu.start_date IS NULL OR fu.start_date <= SYSDATE)
      AND (fu.end_date IS NULL OR fu.end_date > SYSDATE);
    exigir(l_cantidad = 1, 'Usuario de auditoría inexistente o inactivo.');

    SELECT gl.ledger_id, gl.chart_of_accounts_id, gl.currency_code, fc.precision
    INTO l_ledger_id, l_coa_id, l_moneda, l_precision
    FROM ap_system_parameters_all aspa,
         gl_ledgers gl,
         fnd_currencies fc
    WHERE aspa.org_id = :p_org_id
      AND gl.ledger_id = aspa.set_of_books_id
      AND fc.currency_code = gl.currency_code;
    exigir(:p_amount = ROUND(:p_amount, l_precision),
            'El importe excede la precisión de la moneda del libro.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_suppliers aps,
         ap_supplier_sites_all assa
    WHERE aps.vendor_id = :p_vendor_id
      AND assa.vendor_id = aps.vendor_id
      AND assa.vendor_site_id = :p_vendor_site_id
      AND assa.org_id = :p_org_id
      AND assa.pay_site_flag = 'Y'
      AND (aps.start_date_active IS NULL OR aps.start_date_active <= SYSDATE)
      AND (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE)
      AND (assa.inactive_date IS NULL OR assa.inactive_date > SYSDATE);
    exigir(l_cantidad = 1, 'El sitio no es de pago, está inactivo o no pertenece al proveedor/OU.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_terms_b atb
    WHERE atb.term_id = :p_terms_id
      AND (atb.start_date_active IS NULL OR atb.start_date_active <= l_fecha_factura)
      AND (atb.end_date_active IS NULL OR atb.end_date_active >= l_fecha_factura);
    exigir(l_cantidad = 1, 'Términos de pago inexistentes o no vigentes.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM gl_code_combinations gcc
    WHERE gcc.code_combination_id = :p_expense_ccid
      AND gcc.chart_of_accounts_id = l_coa_id
      AND gcc.enabled_flag = 'Y'
      AND gcc.summary_flag = 'N'
      AND gcc.detail_posting_allowed_flag = 'Y'
      AND (gcc.start_date_active IS NULL OR gcc.start_date_active <= l_fecha_contable)
      AND (gcc.end_date_active IS NULL OR gcc.end_date_active >= l_fecha_contable);
    exigir(l_cantidad = 1, 'Cuenta inválida para el plan contable o la fecha.');

    SELECT COUNT(*)
    INTO l_cantidad
    FROM gl_period_statuses gps
    WHERE gps.application_id = 200
      AND gps.set_of_books_id = l_ledger_id
      AND gps.adjustment_period_flag = 'N'
      AND gps.closing_status = 'O'
      AND l_fecha_contable BETWEEN gps.start_date AND gps.end_date;
    exigir(l_cantidad = 1, 'La plantilla exige un período AP normal abierto.');

    -- Control preventivo; no reemplaza una clave externa ni evita carreras concurrentes.
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_invoices_all aia
    WHERE aia.vendor_id = :p_vendor_id
      AND aia.invoice_num = :p_invoice_num;
    exigir(l_cantidad = 0, 'Ya existe ese número de factura para el proveedor.');
    SELECT COUNT(*)
    INTO l_cantidad
    FROM ap_invoices_interface aii
    WHERE aii.vendor_id = :p_vendor_id
      AND aii.invoice_num = :p_invoice_num;
    exigir(l_cantidad = 0, 'Ya existe esa factura en la interfaz.');

    SELECT ap_invoices_interface_s.NEXTVAL,
           ap_invoice_lines_interface_s.NEXTVAL
    INTO l_invoice_id, l_line_id
    FROM dual;

    INSERT INTO ap_invoices_interface (
        invoice_id, invoice_num, invoice_type_lookup_code,
        invoice_date, vendor_id, vendor_site_id, invoice_amount,
        invoice_currency_code, terms_id, description, source, group_id,
        org_id, gl_date, creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        l_invoice_id, :p_invoice_num, 'STANDARD',
        l_fecha_factura, :p_vendor_id, :p_vendor_site_id, :p_amount,
        l_moneda, :p_terms_id, :p_description, :p_source, :p_group_id,
        :p_org_id, l_fecha_contable, SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    -- No asignar NEW al STATUS de facturas: el importador selecciona NULL/rechazadas.
    INSERT INTO ap_invoice_lines_interface (
        invoice_id, invoice_line_id, line_number, line_type_lookup_code,
        amount, accounting_date, description, dist_code_combination_id,
        org_id, creation_date, created_by, last_update_date, last_updated_by
    ) VALUES (
        l_invoice_id, l_line_id, 1, 'ITEM',
        :p_amount, l_fecha_contable, :p_description, :p_expense_ccid,
        :p_org_id, SYSDATE, :p_created_by, SYSDATE, :p_created_by
    );
    DBMS_OUTPUT.PUT_LINE('INVOICE_ID de interfaz: ' || l_invoice_id);
    DBMS_OUTPUT.PUT_LINE('INVOICE_LINE_ID de interfaz: ' || l_line_id);
    DBMS_OUTPUT.PUT_LINE('Revisar y decidir COMMIT o ROLLBACK antes de importar.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO carga_ap_factura;
        RAISE;
END;
/

-- Lanzamiento estándar:
-- 1. Confirmar las filas y ejecutar COMMIT explícitamente si son correctas.
-- 2. En una responsabilidad AP con acceso a p_org_id, enviar
--    Payables Open Interface Import con el mismo SOURCE y GROUP_ID.
-- 3. Revisar los parámetros SRS instalados; no omitir el grupo de este lote.
-- 4. Para la primera prueba, no purgar los registros importados.
-- 5. Revisar solicitud, rechazos y factura final. Importar no equivale
--    a validar, aprobar, contabilizar o pagar la factura.
