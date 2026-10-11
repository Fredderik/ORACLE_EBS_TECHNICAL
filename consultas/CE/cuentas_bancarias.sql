/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : cuentas_bancarias.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Una fila por cuenta; incluye cuentas sin usos.
-- Los números se muestran mediante los campos enmascarados de CE.
-- No filtra por vigencia; muestra fechas e indicadores para su revisión.
SELECT
    cba.bank_account_id, cba.bank_account_name,
    cba.masked_account_num, cba.masked_iban, cba.currency_code,
    cba.bank_id, hp_banco.party_name banco,
    cba.bank_branch_id, hp_sucursal.party_name sucursal,
    cba.account_owner_org_id, cba.account_owner_party_id,
    cba.account_holder_name, cba.account_classification,
    cba.start_date, cba.end_date,
    cba.ap_use_allowed_flag, cba.ar_use_allowed_flag,
    cba.xtr_use_allowed_flag, cba.pay_use_allowed_flag,
    cba.multi_currency_allowed_flag,
    cba.asset_code_combination_id cuenta_efectivo_id,
    cba.cash_clearing_ccid, cba.bank_charges_ccid, cba.bank_errors_ccid
FROM
    ce_bank_accounts cba,
    hz_parties hp_banco,
    hz_parties hp_sucursal
WHERE
    (:p_bank_account_id IS NULL OR cba.bank_account_id = :p_bank_account_id)
    AND (:p_bank_id IS NULL OR cba.bank_id = :p_bank_id)
    AND (:p_owner_org_id IS NULL OR cba.account_owner_org_id = :p_owner_org_id)
    AND cba.bank_id = hp_banco.party_id(+)
    AND cba.bank_branch_id = hp_sucursal.party_id(+)
ORDER BY cba.bank_account_id
/
-- Consulta 2: Una fila por uso registrado; solo cuentas con usos.
-- p_org_id es la OU del uso, no ACCOUNT_OWNER_ORG_ID de la cuenta.
SELECT
    cba.bank_account_id, cba.bank_account_name,
    cba.masked_account_num, cba.masked_iban, cba.currency_code,
    cba.bank_id, hp_banco.party_name banco,
    cba.bank_branch_id, hp_sucursal.party_name sucursal,
    cba.account_owner_org_id, cba.account_owner_party_id,
    cba.account_holder_name, cba.account_classification,
    cba.start_date, cba.end_date,
    cba.ap_use_allowed_flag, cba.ar_use_allowed_flag,
    cba.xtr_use_allowed_flag, cba.pay_use_allowed_flag,
    cba.multi_currency_allowed_flag,
    cba.asset_code_combination_id cuenta_efectivo_id,
    cba.cash_clearing_ccid, cba.bank_charges_ccid, cba.bank_errors_ccid,
    cbaua.bank_acct_use_id, cbaua.org_id, cbaua.legal_entity_id,
    cbaua.primary_flag, cbaua.end_date fin_uso,
    cbaua.ap_use_enable_flag, cbaua.ar_use_enable_flag,
    cbaua.xtr_use_enable_flag, cbaua.pay_use_enable_flag
FROM
    ce_bank_accounts cba,
    hz_parties hp_banco,
    hz_parties hp_sucursal,
    ce_bank_acct_uses_all cbaua
WHERE
    (:p_bank_account_id IS NULL OR cba.bank_account_id = :p_bank_account_id)
    AND (:p_bank_id IS NULL OR cba.bank_id = :p_bank_id)
    AND (:p_owner_org_id IS NULL OR cba.account_owner_org_id = :p_owner_org_id)
    AND cba.bank_id = hp_banco.party_id(+)
    AND cba.bank_branch_id = hp_sucursal.party_id(+)
    AND cba.bank_account_id = cbaua.bank_account_id
    AND (:p_org_id IS NULL OR cbaua.org_id = :p_org_id)
ORDER BY cba.bank_account_id, cbaua.org_id, cbaua.bank_acct_use_id;
