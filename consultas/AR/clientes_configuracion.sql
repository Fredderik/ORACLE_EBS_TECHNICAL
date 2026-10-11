/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : clientes_configuracion.sql                                  ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Clientes, sitios, contactos y cobros.                       ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_language (código de idioma EBS; por ejemplo, US).           ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_cust_account_id (NUMBER), p_account_number (VARCHAR2).                 ║
║    * p_org_id (NUMBER; unidad operativa para los detalles).                   ║
║                                                                               ║
║  Notas          : Oracle EBS R12 en adelante; tablas base.                    ║
║                   Uniones por igualdad en WHERE; externas con (+).            ║
║                   Sin idioma ni organización obtenidos de la sesión.          ║
║                   Pendiente validación de ejecución en Oracle EBS.            ║
║                                                                               ║
║  Actualizaciones:                                                             ║
║    10/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                  ║
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Seis consultas independientes para no multiplicar contactos por cuentas.
-- Las cuentas de cliente son globales; p_org_id filtra sus detalles locales.
-- Se conservan configuraciones globales y registros inactivos para análisis.
-- No se calcula herencia, disponibilidad de crédito ni selección de cobro.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Cuenta de cliente y tercero TCA.
SELECT hca.cust_account_id, hca.account_number, hca.account_name,
       hca.party_id, hp.party_number, hp.party_name, hp.party_type,
       hca.status estado_cuenta, hp.status estado_tercero,
       hca.customer_type, hca.customer_class_code,
       hca.creation_date, hca.last_update_date
FROM hz_cust_accounts hca,
     hz_parties hp
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.party_id = hp.party_id(+)
ORDER BY hca.cust_account_id
/
-- Consulta 2: Sitios y usos (BILL_TO, SHIP_TO y otros), con su dirección.
-- Una fila por uso; conserva sitios que aún no tienen usos.
SELECT hca.cust_account_id, hca.account_number,
       hcasa.cust_acct_site_id, hcasa.org_id, hcasa.status estado_sitio,
       hcasa.party_site_id, hps.party_site_number,
       hl.location_id, hl.address1, hl.address2, hl.address3,
       hl.city, hl.state, hl.province, hl.postal_code, hl.country,
       hcsua.site_use_id, hcsua.site_use_code, hcsua.location referencia_uso,
       hcsua.status estado_uso, hcsua.primary_flag, hcsua.bill_to_site_use_id,
       hcsua.payment_term_id, rtt.name condiciones_pago,
       hcsua.gl_id_rec cuenta_por_cobrar_id,
       hcsua.gl_id_rev cuenta_ingresos_id
FROM hz_cust_accounts hca,
     hz_cust_acct_sites_all hcasa,
     hz_party_sites hps,
     hz_locations hl,
     hz_cust_site_uses_all hcsua,
     ra_terms_tl rtt
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.cust_account_id = hcasa.cust_account_id
    AND (:p_org_id IS NULL OR hcasa.org_id = :p_org_id)
    AND hcasa.party_site_id = hps.party_site_id(+)
    AND hps.location_id = hl.location_id(+)
    AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id(+)
    AND hcasa.org_id = hcsua.org_id(+)
    AND hcsua.payment_term_id = rtt.term_id(+)
    AND rtt.language(+) = :p_language
ORDER BY hca.cust_account_id, hcasa.org_id, hcasa.cust_acct_site_id, hcsua.site_use_id
/
-- Consulta 3: Roles de contacto y medios de su relación TCA.
-- Una fila por rol y medio; la dirección inversa de la relación no se mezcla.
-- Se conservan roles sin relación o medio disponible para poder diagnosticarlos.
SELECT hca.cust_account_id, hca.account_number,
       hcar.cust_account_role_id, hcar.cust_acct_site_id,
       hcar.party_id tercero_relacion_id, hcar.status estado_rol, hcar.primary_flag,
       hr.relationship_id, hr.status estado_relacion,
       hr.start_date inicio_relacion, hr.end_date fin_relacion,
       hp_persona.party_id persona_id, hp_persona.party_name nombre_contacto,
       hcp.contact_point_id, hcp.contact_point_type,
       hcp.status estado_medio, hcp.primary_flag medio_principal,
       hcp.email_address, hcp.phone_country_code, hcp.phone_area_code,
       hcp.phone_number, hcp.phone_extension, hcp.url
FROM hz_cust_accounts hca,
     hz_cust_account_roles hcar,
     hz_relationships hr,
     hz_parties hp_persona,
     hz_contact_points hcp
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.cust_account_id = hcar.cust_account_id
    AND hcar.role_type = 'CONTACT'
    AND (:p_org_id IS NULL OR hcar.cust_acct_site_id IS NULL OR EXISTS
         (SELECT 1 FROM hz_cust_acct_sites_all hcasa
           WHERE hcasa.cust_acct_site_id = hcar.cust_acct_site_id
             AND hcasa.cust_account_id = hca.cust_account_id
             AND hcasa.org_id = :p_org_id))
    AND hcar.party_id = hr.party_id(+)
    AND hr.subject_type(+) = 'PERSON'
    AND hr.subject_table_name(+) = 'HZ_PARTIES'
    AND hr.object_table_name(+) = 'HZ_PARTIES'
    AND hr.relationship_code(+) = 'CONTACT_OF'
    AND hr.subject_id = hp_persona.party_id(+)
    AND hcar.party_id = hcp.owner_table_id(+)
    AND hcp.owner_table_name(+) = 'HZ_PARTIES'
ORDER BY hca.cust_account_id, hcar.cust_account_role_id, hcp.contact_point_id
/
-- Consulta 4: Perfil de crédito/cobranza de cuenta o uso de sitio.
-- No incluye perfiles exclusivos del tercero sin cuenta asociada.
SELECT hca.cust_account_id, hca.account_number,
       hcp.cust_account_profile_id, hcp.site_use_id, hcp.status,
       hcp.profile_class_id, hcp.collector_id,
       hcp.credit_checking, hcp.credit_hold, hcp.credit_rating, hcp.risk_code,
       hcp.standard_terms, rtt.name condiciones_pago,
       hcp.discount_terms, hcp.dunning_letters, hcp.send_statements
FROM hz_cust_accounts hca,
     hz_customer_profiles hcp,
     ra_terms_tl rtt
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.cust_account_id = hcp.cust_account_id
    AND (:p_org_id IS NULL OR hcp.site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa
           WHERE hcsua.site_use_id = hcp.site_use_id
             AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
             AND hcasa.cust_account_id = hca.cust_account_id
             AND hcasa.org_id = :p_org_id
             AND hcsua.org_id = hcasa.org_id))
    AND hcp.standard_terms = rtt.term_id(+)
    AND rtt.language(+) = :p_language
ORDER BY hca.cust_account_id, hcp.site_use_id, hcp.cust_account_profile_id
/
-- Consulta 5: Métodos de recibo asignados a cuenta o uso de sitio.
SELECT hca.cust_account_id, hca.account_number,
       rcrm.cust_receipt_method_id, rcrm.site_use_id, rcrm.receipt_method_id,
       arm.name metodo_recibo, arm.receipt_class_id,
       rcrm.primary_flag, rcrm.start_date inicio_asignacion,
       rcrm.end_date fin_asignacion,
       arm.start_date inicio_metodo, arm.end_date fin_metodo
FROM hz_cust_accounts hca,
     ra_cust_receipt_methods rcrm,
     ar_receipt_methods arm
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.cust_account_id = rcrm.customer_id
    AND (:p_org_id IS NULL OR rcrm.site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa
           WHERE hcsua.site_use_id = rcrm.site_use_id
             AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
             AND hcasa.cust_account_id = hca.cust_account_id
             AND hcasa.org_id = :p_org_id
             AND hcsua.org_id = hcasa.org_id))
    AND rcrm.receipt_method_id = arm.receipt_method_id(+)
ORDER BY hca.cust_account_id, rcrm.site_use_id, rcrm.cust_receipt_method_id
/
-- Consulta 6: Pagadores y cuentas bancarias externas para cobros.
-- Incluye niveles de tercero, cuenta y uso de sitio; se muestran sus claves.
-- Una configuración de tercero puede aparecer en varias cuentas del tercero.
-- Los datos son asignaciones registradas, no la cuenta efectiva de un cobro.
-- El pagador sin instrumento bancario se conserva; sin pagador no hay filas.
-- Se utilizan números enmascarados según la configuración de Oracle Payments.
SELECT hca.cust_account_id, hca.account_number, hca.party_id,
       iepa.ext_payer_id, iepa.cust_account_id cuenta_pagador_id,
       iepa.acct_site_use_id, iepa.org_id, iepa.org_type,
       CASE
           WHEN iepa.acct_site_use_id IS NOT NULL THEN 'Uso de sitio'
           WHEN iepa.cust_account_id IS NOT NULL THEN 'Cuenta de cliente'
           ELSE 'Tercero'
       END nivel_configuracion,
       iepa.payment_function,
       ipiua.instrument_payment_use_id, ipiua.order_of_preference,
       ipiua.start_date inicio_asignacion, ipiua.end_date fin_asignacion,
       ieba.ext_bank_account_id, ieba.bank_account_name,
       ieba.masked_bank_account_num, ieba.masked_iban,
       ieba.bank_account_type, ieba.currency_code, ieba.country_code,
       ieba.bank_id, hp_banco.party_name banco_nombre,
       ieba.branch_id, hp_sucursal.party_name sucursal_nombre,
       ieba.start_date inicio_cuenta, ieba.end_date fin_cuenta
FROM hz_cust_accounts hca,
     iby_external_payers_all iepa,
     iby_pmt_instr_uses_all ipiua,
     iby_ext_bank_accounts ieba,
     hz_parties hp_banco,
     hz_parties hp_sucursal
WHERE
    (:p_cust_account_id IS NULL OR hca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR hca.account_number = :p_account_number)
    AND hca.party_id = iepa.party_id
    AND (iepa.cust_account_id IS NULL OR iepa.cust_account_id = hca.cust_account_id)
    AND iepa.payment_function = 'CUSTOMER_PAYMENT'
    -- Incluso sin filtro de organización, el uso debe pertenecer a la cuenta.
    AND (iepa.acct_site_use_id IS NULL OR EXISTS
         (SELECT 1 FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa
           WHERE hcsua.site_use_id = iepa.acct_site_use_id
             AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
             AND hcasa.cust_account_id = hca.cust_account_id
             AND hcsua.org_id = hcasa.org_id))
    AND (:p_org_id IS NULL OR iepa.org_id IS NULL
         OR (iepa.org_id = :p_org_id AND iepa.org_type = 'OPERATING_UNIT'))
    AND (:p_org_id IS NULL OR iepa.acct_site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all hcsua, hz_cust_acct_sites_all hcasa
           WHERE hcsua.site_use_id = iepa.acct_site_use_id
             AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
             AND hcasa.cust_account_id = hca.cust_account_id
             AND hcasa.org_id = :p_org_id
             AND hcsua.org_id = hcasa.org_id))
    AND iepa.ext_payer_id = ipiua.ext_pmt_party_id(+)
    AND iepa.payment_function = ipiua.payment_function(+)
    AND ipiua.payment_flow(+) = 'FUNDS_CAPTURE'
    AND ipiua.instrument_type(+) = 'BANKACCOUNT'
    AND ipiua.instrument_id = ieba.ext_bank_account_id(+)
    AND ieba.bank_id = hp_banco.party_id(+)
    AND ieba.branch_id = hp_sucursal.party_id(+)
ORDER BY hca.cust_account_id, iepa.ext_payer_id, ipiua.order_of_preference,
         ipiua.instrument_payment_use_id;
