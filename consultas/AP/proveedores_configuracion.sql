/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : proveedores_configuracion.sql                               ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Proveedores, sitios, contactos y pagos.                     ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_language (código de idioma EBS; por ejemplo, US).           ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_vendor_id (NUMBER), p_vendor_num (VARCHAR2; número del proveedor).     ║
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

-- Cinco resultados independientes. No se cruzan contactos con cuentas.
-- La cabecera del proveedor es global y no se filtra por p_org_id.
-- En contactos y pagos se conservan los registros de nivel global.
-- Se incluyen registros inactivos; revisar indicadores y fechas de vigencia.
-- Los métodos y cuentas son configuraciones registradas; no se determina
-- la cuenta que elegirá el motor de pagos ni se reconstruye su herencia.
-- Cada / ejecuta el SELECT anterior: no añadir ; antes del separador.

-- Consulta 1: Datos generales y valores predeterminados del proveedor.
SELECT
    aps.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name,
    aps.party_id,
    aps.vendor_type_lookup_code,
    aps.enabled_flag,
    aps.start_date_active,
    aps.end_date_active,
    aps.invoice_currency_code,
    aps.payment_currency_code,
    aps.terms_id,
    att.name condiciones_pago,
    aps.pay_group_lookup_code,
    aps.hold_all_payments_flag,
    aps.hold_future_payments_flag,
    aps.hold_reason,
    aps.allow_awt_flag,
    aps.awt_group_id,
    aps.vat_registration_num,
    aps.creation_date,
    aps.last_update_date
FROM ap_suppliers aps,
     ap_terms_tl att
WHERE
        (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR aps.segment1 = :p_vendor_num)
    AND aps.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
ORDER BY aps.vendor_id
/
-- Consulta 2: Sitios, dirección y configuración de compras y pagos.
-- Una fila por sitio de la organización solicitada. Sin sitios no hay filas.
SELECT
    aps.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name,
    assa.org_id,
    assa.vendor_site_id,
    assa.vendor_site_code,
    assa.party_site_id,
    assa.location_id,
    assa.address_line1,
    assa.address_line2,
    assa.address_line3,
    assa.city,
    assa.state,
    assa.province,
    assa.zip,
    assa.country,
    assa.phone,
    assa.email_address,
    assa.purchasing_site_flag,
    assa.pay_site_flag,
    assa.rfq_only_site_flag,
    assa.inactive_date,
    assa.invoice_currency_code,
    assa.payment_currency_code,
    assa.terms_id,
    att.name condiciones_pago,
    assa.pay_group_lookup_code,
    assa.payment_priority,
    assa.hold_all_payments_flag,
    assa.hold_future_payments_flag,
    assa.hold_unmatched_invoices_flag,
    assa.hold_reason,
    assa.accts_pay_code_combination_id cuenta_pasivo_id,
    assa.prepay_code_combination_id cuenta_anticipo_id,
    assa.distribution_set_id,
    assa.allow_awt_flag,
    assa.awt_group_id
FROM ap_suppliers aps,
     ap_supplier_sites_all assa,
     ap_terms_tl att
WHERE
        (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR aps.segment1 = :p_vendor_num)
    AND aps.vendor_id = assa.vendor_id
    AND (:p_org_id IS NULL OR assa.org_id = :p_org_id)
    AND assa.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
ORDER BY aps.vendor_id, assa.org_id, assa.vendor_site_id
/
-- Consulta 3: Contactos AP y medios de contacto de su relación TCA.
-- EXISTS identifica al proveedor sin duplicar por las dos direcciones TCA.
-- También se admiten contactos antiguos vinculados directamente al sitio AP.
-- Una fila por contacto y medio TCA; sin medios se conserva el contacto.
-- Los campos AP y TCA se muestran separados para revisar su configuración.
-- El medio TCA pertenece a REL_PARTY_ID; no se mezclan los de la persona
-- en otras relaciones ni los teléfonos generales del sitio.
SELECT
    aps.vendor_id,
    aps.segment1 proveedor_numero,
    aps.vendor_name,
    apsc.vendor_contact_id,
    apsc.vendor_site_id,
    apsc.org_party_site_id,
    apsc.per_party_id,
    apsc.rel_party_id,
    apsc.relationship_id,
    NVL(hp.person_first_name, apsc.first_name) nombres,
    NVL(hp.person_last_name, apsc.last_name) apellidos,
    apsc.title cargo_ap,
    apsc.department departamento_ap,
    apsc.email_address correo_ap,
    apsc.area_code codigo_area_ap,
    apsc.phone telefono_ap,
    apsc.inactive_date,
    hcp.contact_point_id,
    hcp.contact_point_type,
    hcp.status estado_medio_tca,
    hcp.primary_flag principal_tca,
    hcp.email_address correo_tca,
    hcp.phone_country_code,
    hcp.phone_area_code,
    hcp.phone_number,
    hcp.phone_extension,
    hcp.url
FROM ap_suppliers aps,
     ap_supplier_contacts apsc,
     hz_parties hp,
     hz_contact_points hcp
WHERE
        (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR aps.segment1 = :p_vendor_num)
    AND (
        EXISTS
        (
            SELECT 1
            FROM hz_relationships hr
            WHERE hr.party_id = apsc.rel_party_id
              AND hr.subject_id = apsc.per_party_id
              AND hr.object_id = aps.party_id
              AND hr.subject_table_name = 'HZ_PARTIES'
              AND hr.object_table_name = 'HZ_PARTIES'
              AND hr.relationship_code = 'CONTACT_OF'
        )
        OR EXISTS
        (
            SELECT 1
            FROM ap_supplier_sites_all assa
            WHERE assa.vendor_site_id = apsc.vendor_site_id
              AND assa.vendor_id = aps.vendor_id
        )
    )
    AND (:p_org_id IS NULL
         OR (apsc.vendor_site_id IS NULL AND apsc.org_party_site_id IS NULL)
         OR EXISTS
         (
             SELECT 1
             FROM ap_supplier_sites_all assa
             WHERE assa.vendor_id = aps.vendor_id
               AND assa.org_id = :p_org_id
               AND (apsc.vendor_site_id IS NULL
                    OR assa.vendor_site_id = apsc.vendor_site_id)
               AND (apsc.org_party_site_id IS NULL
                    OR assa.party_site_id = apsc.org_party_site_id)
         ))
    AND apsc.per_party_id = hp.party_id(+)
    AND apsc.rel_party_id = hcp.owner_table_id(+)
    AND hcp.owner_table_name(+) = 'HZ_PARTIES'
ORDER BY aps.vendor_id, apsc.vendor_contact_id, hcp.contact_point_id
/
-- Consulta 4: Beneficiarios y asignaciones de cuentas bancarias externas.
-- Se consulta IBY, no los campos bancarios antiguos de los sitios AP.
-- Se conserva el beneficiario sin cuenta; sin beneficiario no hay filas.
-- Número e IBAN se muestran con la máscara configurada en Oracle Payments.
WITH beneficiarios AS
(
    SELECT
        aps.vendor_id,
        aps.segment1,
        aps.vendor_name,
        iepa.ext_payee_id,
        iepa.payment_function,
        iepa.org_id,
        iepa.org_type,
        iepa.party_site_id,
        iepa.supplier_site_id,
        iepa.default_payment_method_code,
        iepa.inactive_date,
        iepa.remit_advice_delivery_method,
        iepa.remit_advice_email
    FROM ap_suppliers aps,
         iby_external_payees_all iepa
    WHERE
            (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR aps.segment1 = :p_vendor_num)
        AND aps.party_id = iepa.payee_party_id
        AND iepa.payment_function = 'PAYABLES_DISB'
        AND (:p_org_id IS NULL
             OR (
                 (iepa.org_id IS NULL
                  OR (iepa.org_id = :p_org_id AND iepa.org_type = 'OPERATING_UNIT'))
                 AND (
                     (iepa.supplier_site_id IS NULL AND iepa.party_site_id IS NULL)
                     OR EXISTS
                     (
                         SELECT 1
                         FROM ap_supplier_sites_all assa
                         WHERE assa.vendor_id = aps.vendor_id
                           AND assa.org_id = :p_org_id
                           AND (iepa.supplier_site_id IS NULL
                                OR assa.vendor_site_id = iepa.supplier_site_id)
                           AND (iepa.party_site_id IS NULL
                                OR assa.party_site_id = iepa.party_site_id)
                     )
                 )
             ))
)
SELECT
    ben.vendor_id,
    ben.segment1 proveedor_numero,
    ben.vendor_name,
    ben.ext_payee_id,
    ben.org_id,
    ben.org_type,
    ben.party_site_id,
    ben.supplier_site_id,
    CASE
        WHEN ben.supplier_site_id IS NOT NULL THEN 'Sitio AP'
        WHEN ben.party_site_id IS NOT NULL AND ben.org_id IS NOT NULL
            THEN 'Dirección TCA y organización'
        WHEN ben.party_site_id IS NOT NULL THEN 'Dirección TCA'
        WHEN ben.org_id IS NOT NULL THEN 'Organización'
        ELSE 'Proveedor global'
    END nivel_configuracion,
    ben.inactive_date baja_beneficiario,
    ben.default_payment_method_code,
    ipiua.instrument_payment_use_id,
    ipiua.order_of_preference,
    ipiua.start_date inicio_asignacion,
    ipiua.end_date fin_asignacion,
    ieba.ext_bank_account_id,
    ieba.bank_account_name,
    ieba.masked_bank_account_num,
    ieba.masked_iban,
    ieba.bank_account_type,
    ieba.currency_code,
    ieba.country_code,
    ieba.bank_id,
    hp_banco.party_name banco_nombre,
    ieba.branch_id,
    hp_sucursal.party_name sucursal_nombre,
    ieba.start_date inicio_cuenta,
    ieba.end_date fin_cuenta
FROM beneficiarios ben,
     iby_pmt_instr_uses_all ipiua,
     iby_ext_bank_accounts ieba,
     hz_parties hp_banco,
     hz_parties hp_sucursal
WHERE ben.ext_payee_id = ipiua.ext_pmt_party_id(+)
    AND ben.payment_function = ipiua.payment_function(+)
    AND ipiua.payment_flow(+) = 'DISBURSEMENTS'
    AND ipiua.instrument_type(+) = 'BANKACCOUNT'
    AND ipiua.instrument_id = ieba.ext_bank_account_id(+)
    AND ieba.bank_id = hp_banco.party_id(+)
    AND ieba.branch_id = hp_sucursal.party_id(+)
ORDER BY ben.vendor_id, ben.ext_payee_id, ipiua.order_of_preference,
         ipiua.instrument_payment_use_id
/
-- Consulta 5: Métodos de pago del beneficiario y avisos de remesa.
-- Se separa de las cuentas para no multiplicar métodos por cuentas.
WITH beneficiarios AS
(
    SELECT
        aps.vendor_id,
        aps.segment1,
        aps.vendor_name,
        iepa.ext_payee_id,
        iepa.payment_function,
        iepa.org_id,
        iepa.org_type,
        iepa.party_site_id,
        iepa.supplier_site_id,
        iepa.default_payment_method_code,
        iepa.inactive_date,
        iepa.remit_advice_delivery_method,
        iepa.remit_advice_email
    FROM ap_suppliers aps,
         iby_external_payees_all iepa
    WHERE
            (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR aps.segment1 = :p_vendor_num)
        AND aps.party_id = iepa.payee_party_id
        AND iepa.payment_function = 'PAYABLES_DISB'
        AND (:p_org_id IS NULL
             OR (
                 (iepa.org_id IS NULL
                  OR (iepa.org_id = :p_org_id AND iepa.org_type = 'OPERATING_UNIT'))
                 AND (
                     (iepa.supplier_site_id IS NULL AND iepa.party_site_id IS NULL)
                     OR EXISTS
                     (
                         SELECT 1
                         FROM ap_supplier_sites_all assa
                         WHERE assa.vendor_id = aps.vendor_id
                           AND assa.org_id = :p_org_id
                           AND (iepa.supplier_site_id IS NULL
                                OR assa.vendor_site_id = iepa.supplier_site_id)
                           AND (iepa.party_site_id IS NULL
                                OR assa.party_site_id = iepa.party_site_id)
                     )
                 )
             ))
)
SELECT
    ben.vendor_id,
    ben.segment1 proveedor_numero,
    ben.vendor_name,
    ben.ext_payee_id,
    ben.org_id,
    ben.org_type,
    ben.party_site_id,
    ben.supplier_site_id,
    ben.inactive_date baja_beneficiario,
    ben.default_payment_method_code,
    ieppm.ext_party_pmt_mthd_id,
    ieppm.payment_method_code,
    ieppm.primary_flag,
    ieppm.inactive_date baja_metodo,
    ben.remit_advice_delivery_method,
    ben.remit_advice_email
FROM beneficiarios ben,
     iby_ext_party_pmt_mthds ieppm
WHERE ben.ext_payee_id = ieppm.ext_pmt_party_id(+)
    AND ben.payment_function = ieppm.payment_function(+)
    AND ieppm.payment_flow(+) = 'DISBURSEMENTS'
ORDER BY ben.vendor_id, ben.ext_payee_id, ieppm.ext_party_pmt_mthd_id;
