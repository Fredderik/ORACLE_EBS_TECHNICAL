/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : proveedores_configuracion.sql                               ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
    s.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name,
    s.party_id,
    s.vendor_type_lookup_code,
    s.enabled_flag,
    s.start_date_active,
    s.end_date_active,
    s.invoice_currency_code,
    s.payment_currency_code,
    s.terms_id,
    t.name condiciones_pago,
    s.pay_group_lookup_code,
    s.hold_all_payments_flag,
    s.hold_future_payments_flag,
    s.hold_reason,
    s.allow_awt_flag,
    s.awt_group_id,
    s.vat_registration_num,
    s.creation_date,
    s.last_update_date
FROM ap_suppliers s,
     ap_terms_tl t
WHERE
        (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR s.segment1 = :p_vendor_num)
    AND s.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY s.vendor_id
/
-- Consulta 2: Sitios, dirección y configuración de compras y pagos.
-- Una fila por sitio de la organización solicitada. Sin sitios no hay filas.
SELECT
    s.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name,
    ss.org_id,
    ss.vendor_site_id,
    ss.vendor_site_code,
    ss.party_site_id,
    ss.location_id,
    ss.address_line1,
    ss.address_line2,
    ss.address_line3,
    ss.city,
    ss.state,
    ss.province,
    ss.zip,
    ss.country,
    ss.phone,
    ss.email_address,
    ss.purchasing_site_flag,
    ss.pay_site_flag,
    ss.rfq_only_site_flag,
    ss.inactive_date,
    ss.invoice_currency_code,
    ss.payment_currency_code,
    ss.terms_id,
    t.name condiciones_pago,
    ss.pay_group_lookup_code,
    ss.payment_priority,
    ss.hold_all_payments_flag,
    ss.hold_future_payments_flag,
    ss.hold_unmatched_invoices_flag,
    ss.hold_reason,
    ss.accts_pay_code_combination_id cuenta_pasivo_id,
    ss.prepay_code_combination_id cuenta_anticipo_id,
    ss.distribution_set_id,
    ss.allow_awt_flag,
    ss.awt_group_id
FROM ap_suppliers s,
     ap_supplier_sites_all ss,
     ap_terms_tl t
WHERE
        (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR s.segment1 = :p_vendor_num)
    AND s.vendor_id = ss.vendor_id
    AND (:p_org_id IS NULL OR ss.org_id = :p_org_id)
    AND ss.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY s.vendor_id, ss.org_id, ss.vendor_site_id
/
-- Consulta 3: Contactos AP y medios de contacto de su relación TCA.
-- EXISTS identifica al proveedor sin duplicar por las dos direcciones TCA.
-- También se admiten contactos antiguos vinculados directamente al sitio AP.
-- Una fila por contacto y medio TCA; sin medios se conserva el contacto.
-- Los campos AP y TCA se muestran separados para revisar su configuración.
-- El medio TCA pertenece a REL_PARTY_ID; no se mezclan los de la persona
-- en otras relaciones ni los teléfonos generales del sitio.
SELECT
    s.vendor_id,
    s.segment1 proveedor_numero,
    s.vendor_name,
    c.vendor_contact_id,
    c.vendor_site_id,
    c.org_party_site_id,
    c.per_party_id,
    c.rel_party_id,
    c.relationship_id,
    NVL(p.person_first_name, c.first_name) nombres,
    NVL(p.person_last_name, c.last_name) apellidos,
    c.title cargo_ap,
    c.department departamento_ap,
    c.email_address correo_ap,
    c.area_code codigo_area_ap,
    c.phone telefono_ap,
    c.inactive_date,
    cp.contact_point_id,
    cp.contact_point_type,
    cp.status estado_medio_tca,
    cp.primary_flag principal_tca,
    cp.email_address correo_tca,
    cp.phone_country_code,
    cp.phone_area_code,
    cp.phone_number,
    cp.phone_extension,
    cp.url
FROM ap_suppliers s,
     ap_supplier_contacts c,
     hz_parties p,
     hz_contact_points cp
WHERE
        (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR s.segment1 = :p_vendor_num)
    AND (
        EXISTS
        (
            SELECT 1
            FROM hz_relationships r
            WHERE r.party_id = c.rel_party_id
              AND r.subject_id = c.per_party_id
              AND r.object_id = s.party_id
              AND r.subject_table_name = 'HZ_PARTIES'
              AND r.object_table_name = 'HZ_PARTIES'
              AND r.relationship_code = 'CONTACT_OF'
        )
        OR EXISTS
        (
            SELECT 1
            FROM ap_supplier_sites_all sx
            WHERE sx.vendor_site_id = c.vendor_site_id
              AND sx.vendor_id = s.vendor_id
        )
    )
    AND (:p_org_id IS NULL
         OR (c.vendor_site_id IS NULL AND c.org_party_site_id IS NULL)
         OR EXISTS
         (
             SELECT 1
             FROM ap_supplier_sites_all sx
             WHERE sx.vendor_id = s.vendor_id
               AND sx.org_id = :p_org_id
               AND (c.vendor_site_id IS NULL
                    OR sx.vendor_site_id = c.vendor_site_id)
               AND (c.org_party_site_id IS NULL
                    OR sx.party_site_id = c.org_party_site_id)
         ))
    AND c.per_party_id = p.party_id(+)
    AND c.rel_party_id = cp.owner_table_id(+)
    AND cp.owner_table_name(+) = 'HZ_PARTIES'
ORDER BY s.vendor_id, c.vendor_contact_id, cp.contact_point_id
/
-- Consulta 4: Beneficiarios y asignaciones de cuentas bancarias externas.
-- Se consulta IBY, no los campos bancarios antiguos de los sitios AP.
-- Se conserva el beneficiario sin cuenta; sin beneficiario no hay filas.
-- Número e IBAN se muestran con la máscara configurada en Oracle Payments.
WITH beneficiarios AS
(
    SELECT
        s.vendor_id,
        s.segment1,
        s.vendor_name,
        ep.ext_payee_id,
        ep.payment_function,
        ep.org_id,
        ep.org_type,
        ep.party_site_id,
        ep.supplier_site_id,
        ep.default_payment_method_code,
        ep.inactive_date,
        ep.remit_advice_delivery_method,
        ep.remit_advice_email
    FROM ap_suppliers s,
         iby_external_payees_all ep
    WHERE
            (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR s.segment1 = :p_vendor_num)
        AND s.party_id = ep.payee_party_id
        AND ep.payment_function = 'PAYABLES_DISB'
        AND (:p_org_id IS NULL
             OR (
                 (ep.org_id IS NULL
                  OR (ep.org_id = :p_org_id AND ep.org_type = 'OPERATING_UNIT'))
                 AND (
                     (ep.supplier_site_id IS NULL AND ep.party_site_id IS NULL)
                     OR EXISTS
                     (
                         SELECT 1
                         FROM ap_supplier_sites_all sx
                         WHERE sx.vendor_id = s.vendor_id
                           AND sx.org_id = :p_org_id
                           AND (ep.supplier_site_id IS NULL
                                OR sx.vendor_site_id = ep.supplier_site_id)
                           AND (ep.party_site_id IS NULL
                                OR sx.party_site_id = ep.party_site_id)
                     )
                 )
             ))
)
SELECT
    b.vendor_id,
    b.segment1 proveedor_numero,
    b.vendor_name,
    b.ext_payee_id,
    b.org_id,
    b.org_type,
    b.party_site_id,
    b.supplier_site_id,
    CASE
        WHEN b.supplier_site_id IS NOT NULL THEN 'Sitio AP'
        WHEN b.party_site_id IS NOT NULL AND b.org_id IS NOT NULL
            THEN 'Dirección TCA y organización'
        WHEN b.party_site_id IS NOT NULL THEN 'Dirección TCA'
        WHEN b.org_id IS NOT NULL THEN 'Organización'
        ELSE 'Proveedor global'
    END nivel_configuracion,
    b.inactive_date baja_beneficiario,
    b.default_payment_method_code,
    u.instrument_payment_use_id,
    u.order_of_preference,
    u.start_date inicio_asignacion,
    u.end_date fin_asignacion,
    a.ext_bank_account_id,
    a.bank_account_name,
    a.masked_bank_account_num,
    a.masked_iban,
    a.bank_account_type,
    a.currency_code,
    a.country_code,
    a.bank_id,
    banco.party_name banco_nombre,
    a.branch_id,
    sucursal.party_name sucursal_nombre,
    a.start_date inicio_cuenta,
    a.end_date fin_cuenta
FROM beneficiarios b,
     iby_pmt_instr_uses_all u,
     iby_ext_bank_accounts a,
     hz_parties banco,
     hz_parties sucursal
WHERE b.ext_payee_id = u.ext_pmt_party_id(+)
    AND b.payment_function = u.payment_function(+)
    AND u.payment_flow(+) = 'DISBURSEMENTS'
    AND u.instrument_type(+) = 'BANKACCOUNT'
    AND u.instrument_id = a.ext_bank_account_id(+)
    AND a.bank_id = banco.party_id(+)
    AND a.branch_id = sucursal.party_id(+)
ORDER BY b.vendor_id, b.ext_payee_id, u.order_of_preference,
         u.instrument_payment_use_id
/
-- Consulta 5: Métodos de pago del beneficiario y avisos de remesa.
-- Se separa de las cuentas para no multiplicar métodos por cuentas.
WITH beneficiarios AS
(
    SELECT
        s.vendor_id,
        s.segment1,
        s.vendor_name,
        ep.ext_payee_id,
        ep.payment_function,
        ep.org_id,
        ep.org_type,
        ep.party_site_id,
        ep.supplier_site_id,
        ep.default_payment_method_code,
        ep.inactive_date,
        ep.remit_advice_delivery_method,
        ep.remit_advice_email
    FROM ap_suppliers s,
         iby_external_payees_all ep
    WHERE
            (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND (:p_vendor_num IS NULL OR s.segment1 = :p_vendor_num)
        AND s.party_id = ep.payee_party_id
        AND ep.payment_function = 'PAYABLES_DISB'
        AND (:p_org_id IS NULL
             OR (
                 (ep.org_id IS NULL
                  OR (ep.org_id = :p_org_id AND ep.org_type = 'OPERATING_UNIT'))
                 AND (
                     (ep.supplier_site_id IS NULL AND ep.party_site_id IS NULL)
                     OR EXISTS
                     (
                         SELECT 1
                         FROM ap_supplier_sites_all sx
                         WHERE sx.vendor_id = s.vendor_id
                           AND sx.org_id = :p_org_id
                           AND (ep.supplier_site_id IS NULL
                                OR sx.vendor_site_id = ep.supplier_site_id)
                           AND (ep.party_site_id IS NULL
                                OR sx.party_site_id = ep.party_site_id)
                     )
                 )
             ))
)
SELECT
    b.vendor_id,
    b.segment1 proveedor_numero,
    b.vendor_name,
    b.ext_payee_id,
    b.org_id,
    b.org_type,
    b.party_site_id,
    b.supplier_site_id,
    b.inactive_date baja_beneficiario,
    b.default_payment_method_code,
    m.ext_party_pmt_mthd_id,
    m.payment_method_code,
    m.primary_flag,
    m.inactive_date baja_metodo,
    b.remit_advice_delivery_method,
    b.remit_advice_email
FROM beneficiarios b,
     iby_ext_party_pmt_mthds m
WHERE b.ext_payee_id = m.ext_pmt_party_id(+)
    AND b.payment_function = m.payment_function(+)
    AND m.payment_flow(+) = 'DISBURSEMENTS'
ORDER BY b.vendor_id, b.ext_payee_id, m.ext_party_pmt_mthd_id;
