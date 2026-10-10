/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : clientes_configuracion.sql                                  ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Seis consultas independientes para no multiplicar contactos por cuentas.
-- Las cuentas de cliente son globales; p_org_id filtra sus detalles locales.
-- Se conservan configuraciones globales y registros inactivos para análisis.
-- No se calcula herencia, disponibilidad de crédito ni selección de cobro.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Cuenta de cliente y tercero TCA.
SELECT ca.cust_account_id, ca.account_number, ca.account_name,
       ca.party_id, p.party_number, p.party_name, p.party_type,
       ca.status estado_cuenta, p.status estado_tercero,
       ca.customer_type, ca.customer_class_code,
       ca.creation_date, ca.last_update_date
FROM hz_cust_accounts ca,
     hz_parties p
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.party_id = p.party_id(+)
ORDER BY ca.cust_account_id
/
-- Consulta 2: Sitios y usos (BILL_TO, SHIP_TO y otros), con su dirección.
-- Una fila por uso; conserva sitios que aún no tienen usos.
SELECT ca.cust_account_id, ca.account_number,
       s.cust_acct_site_id, s.org_id, s.status estado_sitio,
       s.party_site_id, ps.party_site_number,
       loc.location_id, loc.address1, loc.address2, loc.address3,
       loc.city, loc.state, loc.province, loc.postal_code, loc.country,
       u.site_use_id, u.site_use_code, u.location referencia_uso,
       u.status estado_uso, u.primary_flag, u.bill_to_site_use_id,
       u.payment_term_id, t.name condiciones_pago,
       u.gl_id_rec cuenta_por_cobrar_id,
       u.gl_id_rev cuenta_ingresos_id
FROM hz_cust_accounts ca,
     hz_cust_acct_sites_all s,
     hz_party_sites ps,
     hz_locations loc,
     hz_cust_site_uses_all u,
     ra_terms_tl t
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.cust_account_id = s.cust_account_id
    AND (:p_org_id IS NULL OR s.org_id = :p_org_id)
    AND s.party_site_id = ps.party_site_id(+)
    AND ps.location_id = loc.location_id(+)
    AND s.cust_acct_site_id = u.cust_acct_site_id(+)
    AND s.org_id = u.org_id(+)
    AND u.payment_term_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY ca.cust_account_id, s.org_id, s.cust_acct_site_id, u.site_use_id
/
-- Consulta 3: Roles de contacto y medios de su relación TCA.
-- Una fila por rol y medio; la dirección inversa de la relación no se mezcla.
-- Se conservan roles sin relación o medio disponible para poder diagnosticarlos.
SELECT ca.cust_account_id, ca.account_number,
       cr.cust_account_role_id, cr.cust_acct_site_id,
       cr.party_id tercero_relacion_id, cr.status estado_rol, cr.primary_flag,
       r.relationship_id, r.status estado_relacion,
       r.start_date inicio_relacion, r.end_date fin_relacion,
       persona.party_id persona_id, persona.party_name nombre_contacto,
       cp.contact_point_id, cp.contact_point_type,
       cp.status estado_medio, cp.primary_flag medio_principal,
       cp.email_address, cp.phone_country_code, cp.phone_area_code,
       cp.phone_number, cp.phone_extension, cp.url
FROM hz_cust_accounts ca,
     hz_cust_account_roles cr,
     hz_relationships r,
     hz_parties persona,
     hz_contact_points cp
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.cust_account_id = cr.cust_account_id
    AND cr.role_type = 'CONTACT'
    AND (:p_org_id IS NULL OR cr.cust_acct_site_id IS NULL OR EXISTS
         (SELECT 1 FROM hz_cust_acct_sites_all sx
           WHERE sx.cust_acct_site_id = cr.cust_acct_site_id
             AND sx.cust_account_id = ca.cust_account_id
             AND sx.org_id = :p_org_id))
    AND cr.party_id = r.party_id(+)
    AND r.subject_type(+) = 'PERSON'
    AND r.subject_table_name(+) = 'HZ_PARTIES'
    AND r.object_table_name(+) = 'HZ_PARTIES'
    AND r.relationship_code(+) = 'CONTACT_OF'
    AND r.subject_id = persona.party_id(+)
    AND cr.party_id = cp.owner_table_id(+)
    AND cp.owner_table_name(+) = 'HZ_PARTIES'
ORDER BY ca.cust_account_id, cr.cust_account_role_id, cp.contact_point_id
/
-- Consulta 4: Perfil de crédito/cobranza de cuenta o uso de sitio.
-- No incluye perfiles exclusivos del tercero sin cuenta asociada.
SELECT ca.cust_account_id, ca.account_number,
       pr.cust_account_profile_id, pr.site_use_id, pr.status,
       pr.profile_class_id, pr.collector_id,
       pr.credit_checking, pr.credit_hold, pr.credit_rating, pr.risk_code,
       pr.standard_terms, t.name condiciones_pago,
       pr.discount_terms, pr.dunning_letters, pr.send_statements
FROM hz_cust_accounts ca,
     hz_customer_profiles pr,
     ra_terms_tl t
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.cust_account_id = pr.cust_account_id
    AND (:p_org_id IS NULL OR pr.site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all ux, hz_cust_acct_sites_all sx
           WHERE ux.site_use_id = pr.site_use_id
             AND ux.cust_acct_site_id = sx.cust_acct_site_id
             AND sx.cust_account_id = ca.cust_account_id
             AND sx.org_id = :p_org_id
             AND ux.org_id = sx.org_id))
    AND pr.standard_terms = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY ca.cust_account_id, pr.site_use_id, pr.cust_account_profile_id
/
-- Consulta 5: Métodos de recibo asignados a cuenta o uso de sitio.
SELECT ca.cust_account_id, ca.account_number,
       cm.cust_receipt_method_id, cm.site_use_id, cm.receipt_method_id,
       rm.name metodo_recibo, rm.receipt_class_id,
       cm.primary_flag, cm.start_date inicio_asignacion,
       cm.end_date fin_asignacion,
       rm.start_date inicio_metodo, rm.end_date fin_metodo
FROM hz_cust_accounts ca,
     ra_cust_receipt_methods cm,
     ar_receipt_methods rm
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.cust_account_id = cm.customer_id
    AND (:p_org_id IS NULL OR cm.site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all ux, hz_cust_acct_sites_all sx
           WHERE ux.site_use_id = cm.site_use_id
             AND ux.cust_acct_site_id = sx.cust_acct_site_id
             AND sx.cust_account_id = ca.cust_account_id
             AND sx.org_id = :p_org_id
             AND ux.org_id = sx.org_id))
    AND cm.receipt_method_id = rm.receipt_method_id(+)
ORDER BY ca.cust_account_id, cm.site_use_id, cm.cust_receipt_method_id
/
-- Consulta 6: Pagadores y cuentas bancarias externas para cobros.
-- Incluye niveles de tercero, cuenta y uso de sitio; se muestran sus claves.
-- Una configuración de tercero puede aparecer en varias cuentas del tercero.
-- Los datos son asignaciones registradas, no la cuenta efectiva de un cobro.
-- El pagador sin instrumento bancario se conserva; sin pagador no hay filas.
-- Se utilizan números enmascarados según la configuración de Oracle Payments.
SELECT ca.cust_account_id, ca.account_number, ca.party_id,
       ep.ext_payer_id, ep.cust_account_id cuenta_pagador_id,
       ep.acct_site_use_id, ep.org_id, ep.org_type,
       CASE
           WHEN ep.acct_site_use_id IS NOT NULL THEN 'Uso de sitio'
           WHEN ep.cust_account_id IS NOT NULL THEN 'Cuenta de cliente'
           ELSE 'Tercero'
       END nivel_configuracion,
       ep.payment_function,
       iu.instrument_payment_use_id, iu.order_of_preference,
       iu.start_date inicio_asignacion, iu.end_date fin_asignacion,
       ba.ext_bank_account_id, ba.bank_account_name,
       ba.masked_bank_account_num, ba.masked_iban,
       ba.bank_account_type, ba.currency_code, ba.country_code,
       ba.bank_id, banco.party_name banco_nombre,
       ba.branch_id, sucursal.party_name sucursal_nombre,
       ba.start_date inicio_cuenta, ba.end_date fin_cuenta
FROM hz_cust_accounts ca,
     iby_external_payers_all ep,
     iby_pmt_instr_uses_all iu,
     iby_ext_bank_accounts ba,
     hz_parties banco,
     hz_parties sucursal
WHERE
    (:p_cust_account_id IS NULL OR ca.cust_account_id = :p_cust_account_id)
    AND (:p_account_number IS NULL OR ca.account_number = :p_account_number)
    AND ca.party_id = ep.party_id
    AND (ep.cust_account_id IS NULL OR ep.cust_account_id = ca.cust_account_id)
    AND ep.payment_function = 'CUSTOMER_PAYMENT'
    -- Incluso sin filtro de organización, el uso debe pertenecer a la cuenta.
    AND (ep.acct_site_use_id IS NULL OR EXISTS
         (SELECT 1 FROM hz_cust_site_uses_all ux, hz_cust_acct_sites_all sx
           WHERE ux.site_use_id = ep.acct_site_use_id
             AND ux.cust_acct_site_id = sx.cust_acct_site_id
             AND sx.cust_account_id = ca.cust_account_id
             AND ux.org_id = sx.org_id))
    AND (:p_org_id IS NULL OR ep.org_id IS NULL
         OR (ep.org_id = :p_org_id AND ep.org_type = 'OPERATING_UNIT'))
    AND (:p_org_id IS NULL OR ep.acct_site_use_id IS NULL OR EXISTS
         (SELECT 1
            FROM hz_cust_site_uses_all ux, hz_cust_acct_sites_all sx
           WHERE ux.site_use_id = ep.acct_site_use_id
             AND ux.cust_acct_site_id = sx.cust_acct_site_id
             AND sx.cust_account_id = ca.cust_account_id
             AND sx.org_id = :p_org_id
             AND ux.org_id = sx.org_id))
    AND ep.ext_payer_id = iu.ext_pmt_party_id(+)
    AND ep.payment_function = iu.payment_function(+)
    AND iu.payment_flow(+) = 'FUNDS_CAPTURE'
    AND iu.instrument_type(+) = 'BANKACCOUNT'
    AND iu.instrument_id = ba.ext_bank_account_id(+)
    AND ba.bank_id = banco.party_id(+)
    AND ba.branch_id = sucursal.party_id(+)
ORDER BY ca.cust_account_id, ep.ext_payer_id, iu.order_of_preference,
         iu.instrument_payment_use_id;
