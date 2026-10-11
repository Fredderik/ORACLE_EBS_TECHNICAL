/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : cuentas_bancarias.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Cuentas internas y usos por unidad operativa.               ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Opcionales NUMBER: p_bank_account_id, p_bank_id, p_owner_org_id.           ║
║    Opcional NUMBER: p_org_id, solo para la segunda consulta.                  ║
║    NULL omite cada filtro.                                                    ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Estados originales; no requiere parámetro de idioma.        ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Una fila por cuenta; incluye cuentas sin usos.
-- Los números se muestran mediante los campos enmascarados de CE.
-- No filtra por vigencia; muestra fechas e indicadores para su revisión.
SELECT
    a.bank_account_id, a.bank_account_name,
    a.masked_account_num, a.masked_iban, a.currency_code,
    a.bank_id, b.party_name banco,
    a.bank_branch_id, s.party_name sucursal,
    a.account_owner_org_id, a.account_owner_party_id,
    a.account_holder_name, a.account_classification,
    a.start_date, a.end_date,
    a.ap_use_allowed_flag, a.ar_use_allowed_flag,
    a.xtr_use_allowed_flag, a.pay_use_allowed_flag,
    a.multi_currency_allowed_flag,
    a.asset_code_combination_id cuenta_efectivo_id,
    a.cash_clearing_ccid, a.bank_charges_ccid, a.bank_errors_ccid
FROM
    ce_bank_accounts a,
    hz_parties b,
    hz_parties s
WHERE
    (:p_bank_account_id IS NULL OR a.bank_account_id = :p_bank_account_id)
    AND (:p_bank_id IS NULL OR a.bank_id = :p_bank_id)
    AND (:p_owner_org_id IS NULL OR a.account_owner_org_id = :p_owner_org_id)
    AND a.bank_id = b.party_id(+)
    AND a.bank_branch_id = s.party_id(+)
ORDER BY a.bank_account_id
/
-- Consulta 2: Una fila por uso registrado; solo cuentas con usos.
-- p_org_id es la OU del uso, no ACCOUNT_OWNER_ORG_ID de la cuenta.
SELECT
    a.bank_account_id, a.bank_account_name,
    a.masked_account_num, a.masked_iban, a.currency_code,
    a.bank_id, b.party_name banco,
    a.bank_branch_id, s.party_name sucursal,
    a.account_owner_org_id, a.account_owner_party_id,
    a.account_holder_name, a.account_classification,
    a.start_date, a.end_date,
    a.ap_use_allowed_flag, a.ar_use_allowed_flag,
    a.xtr_use_allowed_flag, a.pay_use_allowed_flag,
    a.multi_currency_allowed_flag,
    a.asset_code_combination_id cuenta_efectivo_id,
    a.cash_clearing_ccid, a.bank_charges_ccid, a.bank_errors_ccid,
    u.bank_acct_use_id, u.org_id, u.legal_entity_id,
    u.primary_flag, u.end_date fin_uso,
    u.ap_use_enable_flag, u.ar_use_enable_flag,
    u.xtr_use_enable_flag, u.pay_use_enable_flag
FROM
    ce_bank_accounts a,
    hz_parties b,
    hz_parties s,
    ce_bank_acct_uses_all u
WHERE
    (:p_bank_account_id IS NULL OR a.bank_account_id = :p_bank_account_id)
    AND (:p_bank_id IS NULL OR a.bank_id = :p_bank_id)
    AND (:p_owner_org_id IS NULL OR a.account_owner_org_id = :p_owner_org_id)
    AND a.bank_id = b.party_id(+)
    AND a.bank_branch_id = s.party_id(+)
    AND a.bank_account_id = u.bank_account_id
    AND (:p_org_id IS NULL OR u.org_id = :p_org_id)
ORDER BY a.bank_account_id, u.org_id, u.bank_acct_use_id;
