/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo: diagnostico_autoinvoice.sql
║ Autor: Freddy E. Aparicio M. | Fecha: 17/10/2026 | Versión: 1.0
║ Líneas, errores y distribuciones de AutoInvoice.
║ Parámetros: p_org_id NUMBER; p_batch_source_name, p_context, p_document_ref VARCHAR2 obligatorios.
║ Oracle EBS R12.1/R12.2. Validar en instancia de pruebas.
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Una fila por línea; incluye filas aún sin identificador asignado.
SELECT rila.org_id, rila.interface_line_id, rila.trx_number,
       rila.interface_line_attribute2 referencia_linea,
       rila.line_type, rila.currency_code, rila.amount,
       rila.interface_status, rila.request_id
FROM ra_interface_lines_all rila
WHERE rila.org_id = :p_org_id
  AND rila.batch_source_name = :p_batch_source_name
  AND rila.interface_line_context = :p_context
  AND rila.interface_line_attribute1 = :p_document_ref
ORDER BY rila.interface_line_attribute2
/

-- 2. Errores en resultado independiente para no multiplicar importes.
-- Antes de importar puede no haber errores; eso no confirma una carga correcta.
SELECT rila.interface_line_id, rila.interface_line_attribute2 referencia_linea,
       riea.interface_distribution_id, riea.interface_salescredit_id,
       riea.invalid_value, riea.message_text
FROM ra_interface_lines_all rila, ra_interface_errors_all riea
WHERE rila.org_id = :p_org_id
  AND rila.batch_source_name = :p_batch_source_name
  AND rila.interface_line_context = :p_context
  AND rila.interface_line_attribute1 = :p_document_ref
  AND riea.interface_line_id = rila.interface_line_id
ORDER BY rila.interface_line_id
/

-- 3. Distribuciones por referencia externa: funciona antes de asignar IDs.
-- No se unen con líneas: evita multiplicar filas si existen referencias duplicadas.
SELECT rida.org_id, rida.interface_line_id, rida.interface_distribution_id,
       rida.interface_line_attribute2 referencia_linea,
       rida.account_class, rida.code_combination_id, rida.amount, rida.percent
FROM ra_interface_distributions_all rida
WHERE rida.org_id = :p_org_id
  AND rida.interface_line_context = :p_context
  AND rida.interface_line_attribute1 = :p_document_ref
ORDER BY rida.interface_line_attribute2, rida.account_class
/

-- 4. Resultado final; la purga de interfaz no elimina la factura final.
SELECT rcta.customer_trx_id, rcta.trx_number, rcta.complete_flag,
       rctla.customer_trx_line_id, rctla.line_type, rctla.extended_amount,
       rctla.interface_line_attribute2 referencia_linea
FROM ra_customer_trx_all rcta, ra_customer_trx_lines_all rctla,
     ra_batch_sources_all rbsa
WHERE rcta.org_id = :p_org_id
  AND rctla.customer_trx_id = rcta.customer_trx_id
  AND rctla.org_id = rcta.org_id
  AND rbsa.batch_source_id = rcta.batch_source_id
  AND rbsa.org_id = rcta.org_id
  AND rbsa.name = :p_batch_source_name
  AND rctla.interface_line_context = :p_context
  AND rctla.interface_line_attribute1 = :p_document_ref
ORDER BY rcta.customer_trx_id, rctla.customer_trx_line_id
/
