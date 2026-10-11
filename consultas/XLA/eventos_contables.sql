/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : eventos_contables.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Entidades y eventos, incluidos los aún sin asientos.        ║
║  Parámetros     : Variables de enlace explícitas; NULL omite opcionales.      ║
║    Obligatorio NUMBER: p_application_id.                                      ║
║    Opcionales NUMBER: p_entity_ledger_id, p_entity_id, p_event_id.            ║
║    Opcionales texto: p_entity_code, p_transaction_number.                     ║
║    Opcionales texto: p_event_status, p_process_status.                        ║
║    Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                 ║
║    Las fechas inclusivas filtran EVENT_DATE; libro = libro de la entidad.     ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Estados originales; no requiere parámetro de idioma.        ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- No se exige asiento: permite localizar eventos pendientes o con error.
-- Los identificadores de origen dependen de la aplicación y ENTITY_CODE.
SELECT
    xte.application_id, xte.entity_id, xte.entity_code, xte.transaction_number,
    xte.ledger_id libro_entidad, xte.legal_entity_id,
    xte.source_id_int_1, xte.source_id_int_2, xte.source_id_int_3, xte.source_id_int_4,
    xte.source_id_char_1, xte.source_id_char_2, xte.source_id_char_3, xte.source_id_char_4,
    xe.event_id, xe.event_type_code, xe.event_date,
    xe.event_status_code, xe.process_status_code
FROM xla_transaction_entities xte, xla_events xe
WHERE
    xte.application_id = :p_application_id
    AND xte.application_id = xe.application_id
    AND xte.entity_id = xe.entity_id
    AND (:p_entity_ledger_id IS NULL OR xte.ledger_id = :p_entity_ledger_id)
    AND (:p_entity_id IS NULL OR xte.entity_id = :p_entity_id)
    AND (:p_event_id IS NULL OR xe.event_id = :p_event_id)
    AND (:p_entity_code IS NULL OR xte.entity_code = :p_entity_code)
    AND (:p_transaction_number IS NULL OR xte.transaction_number = :p_transaction_number)
    AND (:p_event_status IS NULL OR xe.event_status_code = :p_event_status)
    AND (:p_process_status IS NULL OR xe.process_status_code = :p_process_status)
    AND (:p_fecha_desde IS NULL
         OR xe.event_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR xe.event_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY xe.event_date, xte.entity_id, xe.event_id;
