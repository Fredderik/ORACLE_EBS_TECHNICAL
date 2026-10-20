/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_operaciones.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Consultar orden, líneas/envíos, aceptaciones y errores por transacción.
║ Parámetros y transacción: README.md y ejemplos_ejecucion.md de este directorio.
║ Oracle EBS R12.1/R12.2. Pendiente compilación y ejecución en EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
-- NUMBER obligatorios: p_org_id, p_po_header_id.
-- NUMBER obligatorio: p_security_group_id (habitualmente 0, verificar).
-- NUMBER opcional: p_interface_transaction_id (NULL no devuelve errores).
-- VARCHAR2 obligatorio: p_language (código EBS, por ejemplo US).
SELECT pha.po_header_id, pha.segment1 numero_orden, pha.org_id,
       pha.revision_num, pha.type_lookup_code, pha.authorization_status,
       pha.closed_code, pha.cancel_flag, pha.agent_id,
       pha.acceptance_required_flag, pha.acceptance_due_date
  FROM po_headers_all pha
 WHERE pha.org_id = :p_org_id
   AND pha.po_header_id = :p_po_header_id
/
SELECT pla.po_line_id, pla.line_num, pla.quantity cantidad_linea,
       pla.unit_price, pla.cancel_flag cancelacion_linea,
       plla.line_location_id, plla.shipment_num,
       plla.quantity cantidad_envio, plla.quantity_received,
       plla.quantity_billed, plla.quantity_cancelled,
       plla.promised_date, plla.need_by_date,
       plla.closed_code, plla.cancel_flag cancelacion_envio
  FROM po_headers_all pha, po_lines_all pla, po_line_locations_all plla
 WHERE pha.org_id = :p_org_id
   AND pha.po_header_id = :p_po_header_id
   AND pla.po_header_id = pha.po_header_id
   AND pla.org_id = pha.org_id
   AND plla.po_line_id(+) = pla.po_line_id
   AND plla.po_header_id(+) = pla.po_header_id
   AND plla.org_id(+) = pla.org_id
 ORDER BY pla.line_num, plla.shipment_num
/
SELECT pa.acceptance_id, pa.revision_num, pa.action_date,
       pa.employee_id, pa.accepted_flag, pa.acceptance_lookup_code,
       pa.note
  FROM po_headers_all pha, po_acceptances pa
 WHERE pha.po_header_id = :p_po_header_id
   AND pha.org_id = :p_org_id
   AND pa.po_header_id = pha.po_header_id
   AND pa.po_release_id IS NULL
 ORDER BY pa.acceptance_id
/
-- Errores de RECORD_ACCEPTANCE: identificador impreso por el bloque.
-- UPDATE_PO devuelve su colección X_API_ERRORS en DBMS_OUTPUT.
SELECT pie.interface_transaction_id, pie.error_message_name,
       pie.error_message, pie.table_name, pie.column_name, pie.processing_date
  FROM po_interface_errors pie
 WHERE pie.interface_type = 'CHANGEPO'
   AND pie.interface_transaction_id = :p_interface_transaction_id
 ORDER BY pie.processing_date
/
-- Códigos disponibles; no derivar el código a partir de la traducción.
SELECT flv.lookup_code, flv.meaning, flv.description,
       flv.enabled_flag, flv.start_date_active, flv.end_date_active
  FROM fnd_lookup_values flv
 WHERE flv.lookup_type = 'ACCEPTANCE TYPE'
   AND flv.view_application_id = 201
   AND flv.language = :p_language
   AND flv.security_group_id = :p_security_group_id
/
