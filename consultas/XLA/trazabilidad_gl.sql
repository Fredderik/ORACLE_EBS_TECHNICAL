/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : trazabilidad_gl.sql                                         ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Relación entre líneas XLA, referencias y asientos GL.       ║
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

-- La transferencia XLA y la contabilización GL son estados diferentes.
-- Sin referencia no implica sin transferencia: depende de conservar referencias.
-- Una línea GL resumida puede corresponder a varias líneas XLA.
-- Los importes se repiten según los vínculos: este detalle no es un total.
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
    gir.je_header_id cabecera_gl_referencia, gir.je_line_num linea_gl_referencia,
    gjl.je_header_id, gjl.je_line_num, gjl.code_combination_id cuenta_gl,
    gjl.entered_dr debe_ingresado_gl, gjl.entered_cr haber_ingresado_gl,
    gjl.accounted_dr debe_contabilizado_gl, gjl.accounted_cr haber_contabilizado_gl,
    gjh.name asiento_gl, gjh.ledger_id libro_gl, gjh.period_name periodo_gl,
    gjh.currency_code moneda_gl, gjh.je_source, gjh.je_category,
    gjh.status estado_asiento_gl, gjh.posted_date fecha_contabilizacion_gl,
    gjb.je_batch_id, gjb.name lote_gl,
    CASE WHEN gir.je_header_id IS NULL THEN 'SIN REFERENCIA GL'
         WHEN gjl.je_header_id IS NULL THEN 'REFERENCIA SIN LINEA GL'
         ELSE 'CON LINEA GL' END diagnostico_vinculo
FROM xla_ae_headers xah, xla_ae_lines xal, gl_import_references gir,
     gl_je_lines gjl, gl_je_headers gjh, gl_je_batches gjb
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
    AND xal.gl_sl_link_id = gir.gl_sl_link_id(+)
    AND xal.gl_sl_link_table = gir.gl_sl_link_table(+)
    AND gir.je_header_id = gjl.je_header_id(+)
    AND gir.je_line_num = gjl.je_line_num(+)
    AND gjl.je_header_id = gjh.je_header_id(+)
    AND gjh.je_batch_id = gjb.je_batch_id(+)
ORDER BY xah.ae_header_id, xal.ae_line_num, gir.je_header_id, gir.je_line_num;
