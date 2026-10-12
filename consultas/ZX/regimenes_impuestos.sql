/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : regimenes_impuestos.sql                                     ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Regímenes e impuestos por propietario.                      ║
║  Obligatorios   :                                                             ║
║  Opcionales     : NULL omite el filtro.                                       ║
║    p_tax_regime_code (VARCHAR2(30)).                                          ║
║    p_content_owner_id (NUMBER).                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Regímenes; p_content_owner_id solo afecta al segundo resultado.
SELECT
    zrb.tax_regime_id, zrb.tax_regime_code, zrb.country_code,
    zrb.tax_currency_code, zrb.effective_from, zrb.effective_to
FROM zx_regimes_b zrb
WHERE (:p_tax_regime_code IS NULL OR zrb.tax_regime_code = :p_tax_regime_code)
ORDER BY zrb.tax_regime_code
/
-- 2. Impuestos; el código puede repetirse entre propietarios de configuración.
-- CONTENT_OWNER_ID no equivale a ORG_ID.
SELECT
    ztb.tax_id, ztb.tax_regime_code, ztb.tax,
    ztb.content_owner_id, ztb.tax_type_code,
    ztb.effective_from, ztb.effective_to,
    ztb.allow_manual_entry_flag, ztb.allow_tax_override_flag
FROM zx_taxes_b ztb
WHERE (:p_tax_regime_code IS NULL OR ztb.tax_regime_code = :p_tax_regime_code)
    AND (:p_content_owner_id IS NULL OR ztb.content_owner_id = :p_content_owner_id)
ORDER BY ztb.tax_regime_code, ztb.tax, ztb.content_owner_id;
