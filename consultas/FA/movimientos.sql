/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : movimientos.sql                                             ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Historial de transacciones del activo.                      ║
║  Obligatorios   :                                                             ║
║    p_book_type_code (VARCHAR2(15)).                                           ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_asset_id (NUMBER).                                                       ║
║    p_asset_number (VARCHAR2(15)).                                             ║
║    p_transaction_type_code (VARCHAR2(20)).                                    ║
║    p_fecha_desde (VARCHAR2(10), YYYY-MM-DD).                                  ║
║    p_fecha_hasta (VARCHAR2(10), YYYY-MM-DD).                                  ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por transacción; incluye altas, ajustes, traslados y bajas.
-- El rango corresponde a TRANSACTION_DATE_ENTERED, no a DATE_EFFECTIVE.
-- Muestra cabeceras, no distribuciones contables ni importes de baja.
SELECT
    fth.transaction_header_id, fth.book_type_code,
    fab.asset_id, fab.asset_number, fat.description descripcion_actual,
    fth.transaction_type_code, fth.transaction_subtype,
    fth.transaction_date_entered, fth.date_effective,
    fth.transaction_name, fth.source_transaction_header_id,
    fth.invoice_transaction_id, fth.mass_reference_id
FROM fa_transaction_headers fth, fa_additions_b fab, fa_additions_tl fat
WHERE
    :p_language IS NOT NULL
    AND fab.asset_id = fat.asset_id(+)
    AND fat.language(+) = :p_language
    AND (:p_asset_id IS NULL OR fab.asset_id = :p_asset_id)
    AND (:p_asset_number IS NULL OR fab.asset_number = :p_asset_number)
    AND fth.asset_id = fab.asset_id
    AND fth.book_type_code = :p_book_type_code
    AND (:p_transaction_type_code IS NULL OR fth.transaction_type_code = :p_transaction_type_code)
    AND (:p_fecha_desde IS NULL OR fth.transaction_date_entered >= TO_DATE(:p_fecha_desde, 'YYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL OR fth.transaction_date_entered < TO_DATE(:p_fecha_hasta, 'YYYY-MM-DD') + 1)
ORDER BY fth.transaction_date_entered, fth.transaction_header_id;
