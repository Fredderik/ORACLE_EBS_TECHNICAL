/*
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : fa_depreciacion_xla.sql                                                  ║
║ Autor          : Freddy E. Aparicio M.                                                    ║
║ Fecha creación : 12/10/2026                                                               ║
║ Versión        : 1.0                                                                      ║
║ Descripción    : Depreciación de activo y cabeceras XLA.                                  ║
║ Parámetros obligatorios (variables de enlace):                                            ║
║ p_asset_id NUMBER: activo.                                                                ║
║ p_book_type_code VARCHAR2: libro de activos.                                              ║
║ p_period_counter NUMBER: contador de período FA.                                          ║
║ p_ledger_id NUMBER: libro contable de la cabecera XLA.                                    ║
║ Oracle EBS R12.1/R12.2. Tablas base; igualdad y (+).                                      ║
║ Pendiente validación de ejecución en Oracle EBS.                                          ║
║ Actualizaciones: 12/10/2026. Versión 1.0. Creación.                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por cabecera; conserva depreciación sin asiento en el libro indicado.
-- DEPRN_AMOUNT se repite con varias cabeceras: no sumar este resultado.
-- Este recorrido cubre depreciación; altas, bajas y ajustes tienen otros eventos.
SELECT fds.asset_id activo_id,
       fds.book_type_code libro_activos,
       fds.period_counter periodo_contador,
       fds.deprn_source_code origen_depreciacion,
       fds.deprn_amount importe_depreciacion,
       fds.event_id evento_id,
       xah.application_id aplicacion_xla_id,
       xah.ae_header_id cabecera_xla_id,
       xah.ledger_id libro_contable_id,
       xah.accounting_entry_status_code estado_contable,
       xah.gl_transfer_status_code estado_transferencia
FROM fa_deprn_summary fds,
     xla_ae_headers xah
WHERE fds.asset_id = :p_asset_id
  AND fds.book_type_code = :p_book_type_code
  AND fds.period_counter = :p_period_counter
  AND xah.event_id(+) = fds.event_id
  AND xah.application_id(+) = 140
  AND xah.ledger_id(+) = :p_ledger_id
ORDER BY xah.ae_header_id;
