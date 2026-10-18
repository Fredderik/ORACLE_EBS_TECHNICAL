/*
╔════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_proveedores.sql                                           ║
║ Autor          : Freddy E. Aparicio M.                                                 ║
║ Fecha creación : 17/10/2026                                                            ║
║ Versión        : 1.0                                                                   ║
║ Descripción    : Estados de proveedor, sitio y contacto por ID de interfaz.            ║
║ Parámetros: declarar todos, incluidos los que admiten NULL.                            ║
║ p_vendor_interface_id NUMBER: proveedor; NULL no devuelve fila de proveedor.           ║
║ p_vendor_site_interface_id NUMBER: sitio; NULL no devuelve fila de sitio.              ║
║ p_vendor_contact_interface_id NUMBER: contacto; NULL no devuelve fila de contacto.     ║
║ p_org_id NUMBER: obligatorio para consultar sitio/contacto.                            ║
║ Solo lectura. R12.1/R12.2. Tablas base; igualdad y (+).                                ║
║ Pendiente ejecución en Oracle EBS.                                                     ║
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.                                    ║
╚════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Los tres identificadores son independientes; no se deben igualar entre sí.
-- El proveedor es global: AP_SUPPLIERS_INT no tiene ORG_ID ni VENDOR_ID.
SELECT asi.vendor_interface_id proveedor_interfaz_id,
       asi.vendor_name nombre_proveedor,
       asi.segment1 numero_proveedor,
       asi.status estado,
       asi.reject_code motivo_rechazo,
       asi.import_request_id solicitud_importacion_id,
       asi.creation_date fecha_carga,
       asi.last_update_date ultima_actualizacion
FROM ap_suppliers_int asi
WHERE asi.vendor_interface_id = :p_vendor_interface_id
/
SELECT assi.vendor_site_interface_id sitio_interfaz_id,
       assi.vendor_interface_id proveedor_interfaz_id,
       assi.vendor_id proveedor_id,
       assi.vendor_site_code codigo_sitio,
       assi.org_id unidad_operativa_id,
       assi.status estado,
       assi.reject_code motivo_rechazo,
       assi.import_request_id solicitud_importacion_id,
       assi.creation_date fecha_carga,
       assi.last_update_date ultima_actualizacion
FROM ap_supplier_sites_int assi
WHERE assi.vendor_site_interface_id = :p_vendor_site_interface_id
  AND assi.org_id = :p_org_id
/
SELECT assci.vendor_contact_interface_id contacto_interfaz_id,
       assci.vendor_id proveedor_id,
       assci.vendor_site_id sitio_id,
       assci.org_id unidad_operativa_id,
       assci.first_name nombre,
       assci.last_name apellido,
       assci.status estado,
       assci.reject_code motivo_rechazo,
       assci.import_request_id solicitud_importacion_id,
       assci.creation_date fecha_carga,
       assci.last_update_date ultima_actualizacion
FROM ap_sup_site_contact_int assci
WHERE assci.vendor_contact_interface_id = :p_vendor_contact_interface_id
  AND assci.org_id = :p_org_id;
