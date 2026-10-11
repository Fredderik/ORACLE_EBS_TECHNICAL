/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : asientos_detalle.sql                                        ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Cabeceras, incluso sin líneas; la entidad es opcional.
-- El libro de la entidad puede diferir del libro contable (libro secundario).
SELECT
    xah.application_id, xah.ledger_id, xah.entity_id, xah.event_id, xah.ae_header_id,
    xah.accounting_date, xah.period_name, xah.je_category_name,
    xah.accounting_entry_status_code, xah.accounting_entry_type_code,
    xah.gl_transfer_status_code, xah.gl_transfer_date, xah.balance_type_code,
    xah.description descripcion_asiento, xah.group_id, xah.request_id,
    xte.entity_code, xte.transaction_number, xte.ledger_id libro_entidad
FROM xla_ae_headers xah, xla_transaction_entities xte
WHERE
    xah.application_id = :p_application_id
    AND xah.ledger_id = :p_ledger_id
    AND (:p_ae_header_id IS NULL OR xah.ae_header_id = :p_ae_header_id)
    AND (:p_event_id IS NULL OR xah.event_id = :p_event_id)
    AND (:p_entity_id IS NULL OR xah.entity_id = :p_entity_id)
    AND (:p_period_name IS NULL OR xah.period_name = :p_period_name)
    AND (:p_accounting_status IS NULL
         OR xah.accounting_entry_status_code = :p_accounting_status)
    AND (:p_transfer_status IS NULL
         OR xah.gl_transfer_status_code = :p_transfer_status)
    AND (:p_fecha_desde IS NULL
         OR xah.accounting_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR xah.accounting_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND xah.application_id = xte.application_id(+)
    AND xah.entity_id = xte.entity_id(+)
ORDER BY xah.accounting_date, xah.ae_header_id
/
-- Consulta 2: Cabeceras y líneas; conserva cabeceras sin líneas.
-- / ejecuta el SELECT anterior sin ; previo.
-- No sumar monedas distintas ni mezclar tipos de saldo.
SELECT
    xah.application_id, xah.ledger_id, xah.entity_id, xah.event_id, xah.ae_header_id,
    xah.accounting_date, xah.period_name, xah.je_category_name,
    xah.accounting_entry_status_code, xah.accounting_entry_type_code,
    xah.gl_transfer_status_code, xah.gl_transfer_date, xah.balance_type_code,
    xah.description descripcion_asiento, xah.group_id, xah.request_id,
    xal.ae_line_num, xal.code_combination_id, xal.accounting_class_code,
    xal.currency_code, xal.entered_dr, xal.entered_cr, xal.accounted_dr, xal.accounted_cr,
    xal.currency_conversion_type, xal.currency_conversion_date,
    xal.currency_conversion_rate, xal.description descripcion_linea,
    xal.party_id, xal.party_site_id, xal.party_type_code,
    xal.gl_sl_link_id, xal.gl_sl_link_table
FROM xla_ae_headers xah, xla_ae_lines xal
WHERE
    xah.application_id = :p_application_id
    AND xah.ledger_id = :p_ledger_id
    AND (:p_ae_header_id IS NULL OR xah.ae_header_id = :p_ae_header_id)
    AND (:p_event_id IS NULL OR xah.event_id = :p_event_id)
    AND (:p_entity_id IS NULL OR xah.entity_id = :p_entity_id)
    AND (:p_period_name IS NULL OR xah.period_name = :p_period_name)
    AND (:p_accounting_status IS NULL
         OR xah.accounting_entry_status_code = :p_accounting_status)
    AND (:p_transfer_status IS NULL
         OR xah.gl_transfer_status_code = :p_transfer_status)
    AND (:p_fecha_desde IS NULL
         OR xah.accounting_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR xah.accounting_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND xah.application_id = xal.application_id(+)
    AND xah.ae_header_id = xal.ae_header_id(+)
ORDER BY xah.accounting_date, xah.ae_header_id, xal.ae_line_num;
