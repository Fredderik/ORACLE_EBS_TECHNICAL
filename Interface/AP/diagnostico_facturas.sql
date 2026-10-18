/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_facturas.sql                                              ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Control del lote y rechazos de cabecera/línea.                        ║
║ Parámetros: declarar todos, incluidos los que admiten NULL.                            ║
║ Obligatorios: p_org_id NUMBER, p_source VARCHAR2, p_group_id VARCHAR2.                 ║
║ Solo lectura. R12.1/R12.2. Tablas base; igualdad y (+).                                ║
║ Pendiente ejecución en Oracle EBS.                                                     ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por cabecera, sin multiplicar los importes por los rechazos.
SELECT aii.invoice_id factura_interfaz_id,
       aii.invoice_num numero_factura,
       aii.vendor_id proveedor_id,
       aii.vendor_site_id sitio_id,
       aii.org_id unidad_operativa_id,
       aii.source origen,
       aii.group_id grupo,
       aii.status estado,
       aii.request_id solicitud_id,
       aii.invoice_currency_code moneda,
       aii.invoice_amount importe_cabecera,
       (SELECT COUNT(*)
        FROM ap_invoice_lines_interface aili
        WHERE aili.invoice_id = aii.invoice_id) cantidad_lineas,
       (SELECT SUM(aili.amount)
        FROM ap_invoice_lines_interface aili
        WHERE aili.invoice_id = aii.invoice_id) importe_lineas
FROM ap_invoices_interface aii
WHERE aii.org_id = :p_org_id
  AND aii.source = :p_source
  AND aii.group_id = :p_group_id
ORDER BY aii.invoice_id
/
-- Solo rechazos. PARENT_TABLE es indispensable: un ID puede coincidir entre tablas.
-- Los códigos se muestran sin depender del idioma de la sesión.
SELECT aii.invoice_id factura_interfaz_id,
       aii.invoice_num numero_factura,
       'CABECERA' nivel_rechazo,
       CAST(NULL AS NUMBER) linea_interfaz_id,
       CAST(NULL AS NUMBER) numero_linea,
       air.reject_lookup_code codigo_rechazo,
       air.last_update_date fecha_rechazo
FROM ap_invoices_interface aii,
     ap_interface_rejections air
WHERE aii.org_id = :p_org_id
  AND aii.source = :p_source
  AND aii.group_id = :p_group_id
  AND air.parent_table = 'AP_INVOICES_INTERFACE'
  AND air.parent_id = aii.invoice_id
UNION ALL
SELECT aii.invoice_id factura_interfaz_id,
       aii.invoice_num numero_factura,
       'LINEA' nivel_rechazo,
       aili.invoice_line_id linea_interfaz_id,
       aili.line_number numero_linea,
       air.reject_lookup_code codigo_rechazo,
       air.last_update_date fecha_rechazo
FROM ap_invoices_interface aii,
     ap_invoice_lines_interface aili,
     ap_interface_rejections air
WHERE aii.org_id = :p_org_id
  AND aii.source = :p_source
  AND aii.group_id = :p_group_id
  AND aili.invoice_id = aii.invoice_id
  AND air.parent_table = 'AP_INVOICE_LINES_INTERFACE'
  AND air.parent_id = aili.invoice_line_id
ORDER BY factura_interfaz_id, nivel_rechazo, numero_linea, codigo_rechazo;
