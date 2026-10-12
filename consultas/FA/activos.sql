/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : activos.sql                                                 ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Activos y valores actuales por libro.                       ║
║  Obligatorios   :                                                             ║
║    p_book_type_code (VARCHAR2(15)).                                           ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_asset_id (NUMBER).                                                       ║
║    p_asset_number (VARCHAR2(15)).                                             ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila vigente por activo y libro; no es una fotografía histórica.
-- Un activo retirado puede conservar una fila vigente en FA_BOOKS.
SELECT
    fab.asset_id, fab.asset_number, fat.description descripcion_activo,
    fab.asset_type, fab.asset_category_id, fab.current_units,
    fab.tag_number, fab.serial_number, fab.manufacturer_name,
    fb.book_type_code, fb.date_placed_in_service,
    fb.cost, fb.original_cost, fb.salvage_value, fb.recoverable_cost,
    fb.deprn_method_code, fb.life_in_months, fb.depreciate_flag,
    fb.date_effective, fb.transaction_header_id_in,
    fb.period_counter_fully_retired
FROM fa_additions_b fab, fa_additions_tl fat, fa_books fb
WHERE
    :p_language IS NOT NULL
    AND fab.asset_id = fat.asset_id(+)
    AND fat.language(+) = :p_language
    AND (:p_asset_id IS NULL OR fab.asset_id = :p_asset_id)
    AND (:p_asset_number IS NULL OR fab.asset_number = :p_asset_number)
    AND fab.asset_id = fb.asset_id
    AND fb.book_type_code = :p_book_type_code
    AND fb.date_ineffective IS NULL
    AND fb.transaction_header_id_out IS NULL
ORDER BY fab.asset_number;
