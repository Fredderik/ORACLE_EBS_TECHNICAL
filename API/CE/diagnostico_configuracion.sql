/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo        : diagnostico_configuracion.sql
║ Autor          : Freddy E. Aparicio M.
║ Fecha creación : 19/10/2026 | Versión: 1.0
║ Descripción    : Revisar IDs creados y usos AP/AR sin vistas funcionales.
║ NUMBER: p_bank_id, p_branch_id, p_legal_entity_id, p_bank_account_id, p_org_id.
║ Declarar todos. NULL no amplía la búsqueda: omite resultados de ese filtro.
║ No usa traducciones; no requiere idioma. Datos de TCA conservan su nombre.
║ Objetivo: EBS R12.1/R12.2. Pendiente ejecución en EBS.
║ Actualizaciones: 19/10/2026 — versión 1.0, creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/
-- IDs TCA devueltos por crear banco y sucursal; no prueba su relación.
SELECT hp.party_id, hp.party_number, hp.party_name, hp.party_type, hp.status
  FROM hz_parties hp
 WHERE hp.party_id IN (:p_bank_id, :p_branch_id)
 ORDER BY hp.party_id
/
SELECT xep.legal_entity_id, xep.name entidad_legal, xep.party_id,
       xep.transacting_entity_flag, xep.effective_from, xep.effective_to
  FROM xle_entity_profiles xep
 WHERE xep.legal_entity_id = :p_legal_entity_id
/
SELECT cba.bank_account_id, cba.bank_account_name,
       '****' || SUBSTR(cba.bank_account_num, -4) numero_enmascarado,
       cba.bank_id, hp_banco.party_name banco,
       cba.bank_branch_id, hp_sucursal.party_name sucursal,
       cba.account_owner_org_id entidad_legal_id, cba.account_owner_party_id,
       cba.currency_code, cba.account_classification,
       cba.ap_use_allowed_flag, cba.ar_use_allowed_flag,
       cba.start_date, cba.end_date, cba.object_version_number
  FROM ce_bank_accounts cba, hz_parties hp_banco, hz_parties hp_sucursal
 WHERE cba.bank_account_id = :p_bank_account_id
   AND cba.account_owner_org_id = :p_legal_entity_id
   AND cba.bank_id = hp_banco.party_id(+)
   AND cba.bank_branch_id = hp_sucursal.party_id(+)
/
SELECT cbaua.bank_acct_use_id, cbaua.bank_account_id, cbaua.org_id,
       cbaua.ap_use_enable_flag, cbaua.ar_use_enable_flag,
       cbaua.end_date, cbaua.object_version_number,
       cgac.asset_code_combination_id, cgac.ap_asset_ccid, cgac.ar_asset_ccid,
       cgac.cash_clearing_ccid, cgac.bank_charges_ccid,
       cgac.object_version_number version_cuentas_contables
  FROM ce_bank_accounts cba, ce_bank_acct_uses_all cbaua, ce_gl_accounts_ccid cgac
 WHERE cba.bank_account_id = :p_bank_account_id
   AND cba.account_owner_org_id = :p_legal_entity_id
   AND cbaua.bank_account_id = cba.bank_account_id
   AND cbaua.org_id = :p_org_id
   AND cgac.bank_acct_use_id(+) = cbaua.bank_acct_use_id
 ORDER BY cbaua.bank_acct_use_id
/
