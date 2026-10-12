/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : tasas.sql                                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Tasas de impuesto y traducciones.                           ║
║  Obligatorios   :                                                             ║
║    p_language (VARCHAR2(4)).                                                  ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_content_owner_id (NUMBER).                                               ║
║    p_tax_regime_code (VARCHAR2(30)).                                          ║
║    p_tax (VARCHAR2(30)).                                                      ║
║    p_tax_rate_code (VARCHAR2(50)).                                            ║
║    p_fecha_vigencia (VARCHAR2(10), YYYY-MM-DD).                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por TAX_RATE_ID; conserva tasas sin traducción solicitada.
-- Se muestran también inactivas: ACTIVE_FLAG y fechas son conceptos distintos.
-- Las tasas por cantidad o por calendario no se reducen a PERCENTAGE_RATE.
SELECT
    zrb.tax_rate_id, zrb.tax_rate_code, zrt.tax_rate_name,
    zrb.content_owner_id, zrb.tax_regime_code, zrb.tax,
    zrb.tax_status_code, zrb.tax_jurisdiction_code,
    zrb.rate_type_code, zrb.percentage_rate, zrb.quantity_rate,
    zrb.uom_code, zrb.schedule_based_rate_flag,
    zrb.active_flag, zrb.effective_from, zrb.effective_to
FROM zx_rates_b zrb, zx_rates_tl zrt
WHERE :p_language IS NOT NULL
    AND zrb.tax_rate_id = zrt.tax_rate_id(+)
    AND zrt.language(+) = :p_language
    AND (:p_content_owner_id IS NULL OR zrb.content_owner_id = :p_content_owner_id)
    AND (:p_tax_regime_code IS NULL OR zrb.tax_regime_code = :p_tax_regime_code)
    AND (:p_tax IS NULL OR zrb.tax = :p_tax)
    AND (:p_tax_rate_code IS NULL OR zrb.tax_rate_code = :p_tax_rate_code)
    AND (:p_fecha_vigencia IS NULL
         OR ((zrb.effective_from IS NULL
              OR zrb.effective_from < TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD') + 1)
         AND (zrb.effective_to IS NULL
              OR zrb.effective_to >= TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD'))))
ORDER BY zrb.tax_regime_code, zrb.tax, zrb.tax_rate_id;
