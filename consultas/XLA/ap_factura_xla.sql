/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : ap_factura_xla.sql                                                       ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Documento de origen, entidad y eventos XLA.                              ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_documento_id NUMBER: ap_invoices_all.invoice_id.                                        ║
║ p_org_id NUMBER: unidad operativa del documento.                                          ║
║ p_entity_ledger_id NUMBER: libro de la entidad XLA, no del asiento.                       ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por evento; conserva el documento sin entidad o sin eventos.
-- No confundir libro de entidad con libro de cabecera (libros secundarios).
SELECT aia.invoice_id documento_id,
       aia.invoice_num documento_numero,
       aia.org_id unidad_operativa_id,
       aia.set_of_books_id libro_documento_id,
       xte.application_id aplicacion_xla_id,
       xte.entity_id entidad_id,
       xte.entity_code entidad_codigo,
       xte.ledger_id libro_entidad_id,
       xe.event_id evento_id,
       xe.event_type_code tipo_evento,
       xe.event_date fecha_evento,
       xe.event_status_code estado_evento,
       xe.process_status_code estado_proceso
FROM ap_invoices_all aia,
     xla_transaction_entities xte,
     xla_events xe
WHERE aia.invoice_id = :p_documento_id
  AND aia.org_id = :p_org_id
  AND xte.source_id_int_1(+) = aia.invoice_id
  AND xte.application_id(+) = 200
  AND xte.entity_code(+) = 'AP_INVOICES'
  AND xte.ledger_id(+) = :p_entity_ledger_id
  AND xe.application_id(+) = xte.application_id
  AND xe.entity_id(+) = xte.entity_id
ORDER BY xte.entity_id, xe.event_id;
