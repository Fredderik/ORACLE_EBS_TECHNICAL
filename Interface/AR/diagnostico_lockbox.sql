/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo: diagnostico_lockbox.sql
║ Autor: Freddy E. Aparicio M. | Fecha: 17/10/2026 | Versión: 1.0
║ Registros y estados de una transmisión AutoLockbox.
║ Parámetros: p_org_id y p_transmission_id NUMBER obligatorios.
║ Oracle EBS R12.1/R12.2. Validar en instancia de pruebas.
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Importar primero el archivo bancario con el formato configurado de Lockbox.
SELECT apia.transmission_id, apia.transmission_record_id,
       apia.record_type, apia.status, apia.batch_name,
       apia.item_number, apia.check_number, apia.customer_number,
       apia.currency_code, apia.remittance_amount,
       apia.overflow_indicator, apia.overflow_sequence,
       apia.invoice1, apia.invoice2, apia.invoice3, apia.invoice4,
       apia.invoice5, apia.invoice6, apia.invoice7, apia.invoice8,
       apia.transmission_request_id
FROM ar_payments_interface_all apia
WHERE apia.org_id = :p_org_id
  AND apia.transmission_id = :p_transmission_id
ORDER BY apia.transmission_record_id
/

-- No sumar importes de cabeceras, detalles y overflow como si fueran recibos.
SELECT apia.record_type, apia.status, COUNT(*) cantidad_registros
FROM ar_payments_interface_all apia
WHERE apia.org_id = :p_org_id
  AND apia.transmission_id = :p_transmission_id
GROUP BY apia.record_type, apia.status
ORDER BY apia.record_type, apia.status
/
