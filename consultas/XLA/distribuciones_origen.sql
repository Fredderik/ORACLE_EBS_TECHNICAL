/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : distribuciones_origen.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una línea puede tener varios vínculos; no sumar los importes de línea aquí.
-- No se supone que SOURCE_DISTRIBUTION_ID_NUM_1 sea siempre una factura.
-- Se conservan líneas sin vínculo; no se eliminan filas mediante DISTINCT.
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
    l.gl_sl_link_id, l.gl_sl_link_table,
    d.event_id evento_vinculo, d.source_distribution_type,
    d.source_distribution_id_num_1, d.source_distribution_id_char_1,
    d.source_distribution_id_num_2, d.source_distribution_id_char_2,
    d.source_distribution_id_num_3, d.source_distribution_id_char_3,
    d.source_distribution_id_num_4, d.source_distribution_id_char_4,
    d.source_distribution_id_num_5, d.source_distribution_id_char_5,
    d.temp_line_num, d.ref_ae_header_id, d.ref_temp_line_num, d.ref_event_id,
    d.event_class_code, d.event_type_code, d.accounting_line_code,
    d.accounting_line_type_code, d.merge_duplicate_code,
    d.unrounded_entered_dr, d.unrounded_entered_cr,
    d.unrounded_accounted_dr, d.unrounded_accounted_cr
FROM xla_ae_headers h, xla_ae_lines l, xla_distribution_links d
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
    AND h.application_id = l.application_id
    AND h.ae_header_id = l.ae_header_id
    AND l.application_id = d.application_id(+)
    AND l.ae_header_id = d.ae_header_id(+)
    AND l.ae_line_num = d.ae_line_num(+)
ORDER BY h.ae_header_id, l.ae_line_num, d.temp_line_num;
