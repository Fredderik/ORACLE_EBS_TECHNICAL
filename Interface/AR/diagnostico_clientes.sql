/*
╔════════════════════════════════════════════════════════════════════════════════════╗
║ Archivo: diagnostico_clientes.sql
║ Autor: Freddy E. Aparicio M. | Fecha: 17/10/2026 | Versión: 1.0
║ Estado de Customer Interface y cuenta creada.
║ Parámetros: p_org_id NUMBER y p_customer_ref VARCHAR2 obligatorios.
║ Oracle EBS R12.1/R12.2. Validar en instancia de pruebas.
║ Actualizaciones: 17/10/2026. Versión 1.0. Creación.
╚════════════════════════════════════════════════════════════════════════════════════╝
*/

-- Los códigos de error deben revisarse con Customer Interface Transfer Report.
SELECT rcia.org_id, rcia.orig_system_customer_ref,
       rcia.orig_system_address_ref, rcia.customer_name,
       rcia.site_use_code, rcia.insert_update_flag, rcia.interface_status
FROM ra_customers_interface_all rcia
WHERE rcia.org_id = :p_org_id
  AND rcia.orig_system_customer_ref = :p_customer_ref
/

-- Separar perfiles evita repetir las filas de direcciones.
SELECT rcpia.org_id, rcpia.orig_system_customer_ref,
       rcpia.orig_system_address_ref, rcpia.customer_profile_class_name,
       rcpia.insert_update_flag, rcpia.interface_status
FROM ra_customer_profiles_int_all rcpia
WHERE rcpia.org_id = :p_org_id
  AND rcpia.orig_system_customer_ref = :p_customer_ref
/

-- La cuenta es global; direcciones/usos pertenecen a una OU.
SELECT hca.cust_account_id, hca.account_number, hca.status estado_cuenta,
       hcasa.cust_acct_site_id, hcsua.site_use_id, hcsua.site_use_code,
       hcsua.status estado_uso
FROM hz_cust_accounts hca, hz_cust_acct_sites_all hcasa,
     hz_cust_site_uses_all hcsua
WHERE hca.orig_system_reference = :p_customer_ref
  AND hcasa.cust_account_id = hca.cust_account_id
  AND hcasa.org_id = :p_org_id
  AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
  AND hcsua.org_id = hcasa.org_id
/
