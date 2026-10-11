/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : asientos_detalle.sql                                        ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Cabeceras y líneas contables de Subledger Accounting.       ║
║  Parámetros     : Variables de enlace explícitas; NULL omite opcionales.      ║
║    Obligatorios NUMBER: p_application_id, p_ledger_id.                        ║
║    Opcionales NUMBER: p_ae_header_id, p_event_id, p_entity_id.                ║
║    Opcionales texto: p_period_name, p_accounting_status, p_transfer_status.   ║
║    Opcionales texto YYYY-MM-DD: p_fecha_desde, p_fecha_hasta.                 ║
║    Las fechas inclusivas filtran ACCOUNTING_DATE de la cabecera.              ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Estados originales; no requiere parámetro de idioma.        ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Cabeceras, incluso sin líneas; la entidad es opcional.
-- El libro de la entidad puede diferir del libro contable (libro secundario).
SELECT
    h.application_id, h.ledger_id, h.entity_id, h.event_id, h.ae_header_id,
    h.accounting_date, h.period_name, h.je_category_name,
    h.accounting_entry_status_code, h.accounting_entry_type_code,
    h.gl_transfer_status_code, h.gl_transfer_date, h.balance_type_code,
    h.description descripcion_asiento, h.group_id, h.request_id,
    t.entity_code, t.transaction_number, t.ledger_id libro_entidad
FROM xla_ae_headers h, xla_transaction_entities t
WHERE
    h.application_id = :p_application_id
    AND h.ledger_id = :p_ledger_id
    AND (:p_ae_header_id IS NULL OR h.ae_header_id = :p_ae_header_id)
    AND (:p_event_id IS NULL OR h.event_id = :p_event_id)
    AND (:p_entity_id IS NULL OR h.entity_id = :p_entity_id)
    AND (:p_period_name IS NULL OR h.period_name = :p_period_name)
    AND (:p_accounting_status IS NULL
         OR h.accounting_entry_status_code = :p_accounting_status)
    AND (:p_transfer_status IS NULL
         OR h.gl_transfer_status_code = :p_transfer_status)
    AND (:p_fecha_desde IS NULL
         OR h.accounting_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.accounting_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.application_id = t.application_id(+)
    AND h.entity_id = t.entity_id(+)
ORDER BY h.accounting_date, h.ae_header_id
/
-- Consulta 2: Cabeceras y líneas; conserva cabeceras sin líneas.
-- / ejecuta el SELECT anterior sin ; previo.
-- No sumar monedas distintas ni mezclar tipos de saldo.
SELECT
    h.application_id, h.ledger_id, h.entity_id, h.event_id, h.ae_header_id,
    h.accounting_date, h.period_name, h.je_category_name,
    h.accounting_entry_status_code, h.accounting_entry_type_code,
    h.gl_transfer_status_code, h.gl_transfer_date, h.balance_type_code,
    h.description descripcion_asiento, h.group_id, h.request_id,
    l.ae_line_num, l.code_combination_id, l.accounting_class_code,
    l.currency_code, l.entered_dr, l.entered_cr, l.accounted_dr, l.accounted_cr,
    l.currency_conversion_type, l.currency_conversion_date,
    l.currency_conversion_rate, l.description descripcion_linea,
    l.party_id, l.party_site_id, l.party_type_code,
    l.gl_sl_link_id, l.gl_sl_link_table
FROM xla_ae_headers h, xla_ae_lines l
WHERE
    h.application_id = :p_application_id
    AND h.ledger_id = :p_ledger_id
    AND (:p_ae_header_id IS NULL OR h.ae_header_id = :p_ae_header_id)
    AND (:p_event_id IS NULL OR h.event_id = :p_event_id)
    AND (:p_entity_id IS NULL OR h.entity_id = :p_entity_id)
    AND (:p_period_name IS NULL OR h.period_name = :p_period_name)
    AND (:p_accounting_status IS NULL
         OR h.accounting_entry_status_code = :p_accounting_status)
    AND (:p_transfer_status IS NULL
         OR h.gl_transfer_status_code = :p_transfer_status)
    AND (:p_fecha_desde IS NULL
         OR h.accounting_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.accounting_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.application_id = l.application_id(+)
    AND h.ae_header_id = l.ae_header_id(+)
ORDER BY h.accounting_date, h.ae_header_id, l.ae_line_num;
