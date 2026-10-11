/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : distribuciones_origen.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Líneas XLA y vínculos con distribuciones de origen.         ║
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

-- Una línea puede tener varios vínculos; no sumar los importes de línea aquí.
-- No se supone que SOURCE_DISTRIBUTION_ID_NUM_1 sea siempre una factura.
-- Se conservan líneas sin vínculo; no se eliminan filas mediante DISTINCT.
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
    xal.gl_sl_link_id, xal.gl_sl_link_table,
    xdl.event_id evento_vinculo, xdl.source_distribution_type,
    xdl.source_distribution_id_num_1, xdl.source_distribution_id_char_1,
    xdl.source_distribution_id_num_2, xdl.source_distribution_id_char_2,
    xdl.source_distribution_id_num_3, xdl.source_distribution_id_char_3,
    xdl.source_distribution_id_num_4, xdl.source_distribution_id_char_4,
    xdl.source_distribution_id_num_5, xdl.source_distribution_id_char_5,
    xdl.temp_line_num, xdl.ref_ae_header_id, xdl.ref_temp_line_num, xdl.ref_event_id,
    xdl.event_class_code, xdl.event_type_code, xdl.accounting_line_code,
    xdl.accounting_line_type_code, xdl.merge_duplicate_code,
    xdl.unrounded_entered_dr, xdl.unrounded_entered_cr,
    xdl.unrounded_accounted_dr, xdl.unrounded_accounted_cr
FROM xla_ae_headers xah, xla_ae_lines xal, xla_distribution_links xdl
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
    AND xah.application_id = xal.application_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xal.application_id = xdl.application_id(+)
    AND xal.ae_header_id = xdl.ae_header_id(+)
    AND xal.ae_line_num = xdl.ae_line_num(+)
ORDER BY xah.ae_header_id, xal.ae_line_num, xdl.temp_line_num;
