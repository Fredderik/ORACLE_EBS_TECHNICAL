/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : eventos_contables.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- No se exige asiento: permite localizar eventos pendientes o con error.
-- Los identificadores de origen dependen de la aplicación y ENTITY_CODE.
SELECT
    t.application_id, t.entity_id, t.entity_code, t.transaction_number,
    t.ledger_id libro_entidad, t.legal_entity_id,
    t.source_id_int_1, t.source_id_int_2, t.source_id_int_3, t.source_id_int_4,
    t.source_id_char_1, t.source_id_char_2, t.source_id_char_3, t.source_id_char_4,
    e.event_id, e.event_type_code, e.event_date,
    e.event_status_code, e.process_status_code
FROM xla_transaction_entities t, xla_events e
WHERE
    t.application_id = :p_application_id
    AND t.application_id = e.application_id
    AND t.entity_id = e.entity_id
    AND (:p_entity_ledger_id IS NULL OR t.ledger_id = :p_entity_ledger_id)
    AND (:p_entity_id IS NULL OR t.entity_id = :p_entity_id)
    AND (:p_event_id IS NULL OR e.event_id = :p_event_id)
    AND (:p_entity_code IS NULL OR t.entity_code = :p_entity_code)
    AND (:p_transaction_number IS NULL OR t.transaction_number = :p_transaction_number)
    AND (:p_event_status IS NULL OR e.event_status_code = :p_event_status)
    AND (:p_process_status IS NULL OR e.process_status_code = :p_process_status)
    AND (:p_fecha_desde IS NULL
         OR e.event_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR e.event_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY e.event_date, t.entity_id, e.event_id;
