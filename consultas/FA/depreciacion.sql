/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : depreciacion.sql                                            ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Depreciación por activo, libro y período.                   ║
║  Obligatorios   :                                                             ║
║    p_book_type_code (VARCHAR2(15)).                                           ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_asset_id (NUMBER).                                                       ║
║    p_asset_number (VARCHAR2(15)).                                             ║
║    p_period_counter (NUMBER).                                                 ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por activo/libro/período. La descripción del activo es actual.
-- YTD_DEPRN y DEPRN_RESERVE son acumulados: no sumarlos entre períodos.
-- Se conserva DEPRN_SOURCE_CODE para distinguir BOOKS, DEPRN y TRACK.
SELECT
    fds.book_type_code, fab.asset_id, fab.asset_number,
    fat.description descripcion_activo,
    fds.period_counter, fdp.period_name, fdp.fiscal_year,
    fds.deprn_source_code, fds.deprn_run_date,
    fds.deprn_amount, fds.ytd_deprn, fds.deprn_reserve,
    fds.adjusted_cost, fds.bonus_deprn_amount, fds.impairment_reserve
FROM fa_deprn_summary fds, fa_deprn_periods fdp,
     fa_additions_b fab, fa_additions_tl fat
WHERE
    :p_language IS NOT NULL
    AND fab.asset_id = fat.asset_id(+)
    AND fat.language(+) = :p_language
    AND (:p_asset_id IS NULL OR fab.asset_id = :p_asset_id)
    AND (:p_asset_number IS NULL OR fab.asset_number = :p_asset_number)
    AND fds.asset_id = fab.asset_id
    AND fds.book_type_code = :p_book_type_code
    AND fds.book_type_code = fdp.book_type_code
    AND fds.period_counter = fdp.period_counter
    AND (:p_period_counter IS NULL OR fds.period_counter = :p_period_counter)
ORDER BY fab.asset_number, fds.period_counter;
