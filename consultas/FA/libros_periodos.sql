/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : libros_periodos.sql                                         ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Libros de activos y períodos.                               ║
║  Obligatorios   :                                                             ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_book_type_code (VARCHAR2(15)).                                           ║
║    p_solo_abiertos (VARCHAR2(1), Y/N).                                        ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Una fila por libro. El filtro de abiertos se aplica solo al resultado 2.
SELECT
    fbc.book_type_code, fbc.book_type_name, fbc.book_class,
    fbc.set_of_books_id, fbc.deprn_calendar, fbc.prorate_calendar,
    fbc.current_fiscal_year, fbc.last_period_counter,
    fbc.last_deprn_run_date, fbc.deprn_status, fbc.deprn_request_id
FROM fa_book_controls fbc
WHERE (:p_book_type_code IS NULL OR fbc.book_type_code = :p_book_type_code)
ORDER BY fbc.book_type_code
/
-- 2. Una fila por libro/período; NULL o N permite consultar todos.
SELECT
    fdp.book_type_code, fdp.period_counter, fdp.period_name,
    fdp.fiscal_year, fdp.period_num,
    fdp.calendar_period_open_date, fdp.calendar_period_close_date,
    fdp.period_open_date, fdp.period_close_date
FROM fa_deprn_periods fdp
WHERE (:p_book_type_code IS NULL OR fdp.book_type_code = :p_book_type_code)
    AND (:p_solo_abiertos IS NULL OR :p_solo_abiertos = 'N'
         OR (:p_solo_abiertos = 'Y' AND fdp.period_close_date IS NULL))
ORDER BY fdp.book_type_code, fdp.period_counter;
