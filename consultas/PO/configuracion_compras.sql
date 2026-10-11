/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : configuracion_compras.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
║  Descripción    : Sitios, compradores y tipos de compras.                     ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorios: p_org_id (NUMBER), p_language (código EBS).                  ║
║    * p_fecha_consulta (VARCHAR2; YYYY-MM-DD; vigencia del nombre HR).         ║
║    Opcionales (NULL omite el filtro de su consulta):                          ║
║    * p_vendor_id (consulta 1), p_agent_id (consulta 2) (NUMBER).              ║
║    * p_line_type_id (consulta 3) (NUMBER).                                    ║
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

-- Los proveedores se comparten con AP. Para bancos y contactos completos,
-- consultar ../AP/proveedores_configuracion.sql con sus propios parámetros.
-- Sitios y tipos de documento usan la unidad operativa indicada.
-- Compradores y tipos de línea son catálogos globales, no permisos por OU.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Proveedores y sitios de la organización, con indicadores de uso.
-- Incluye sitios sin habilitación de compras para revisar su configuración.
SELECT aps.vendor_id, aps.segment1 proveedor_numero, aps.vendor_name,
       aps.enabled_flag, aps.start_date_active, aps.end_date_active,
       assa.org_id, assa.vendor_site_id, assa.vendor_site_code,
       assa.purchasing_site_flag, assa.rfq_only_site_flag, assa.pay_site_flag,
       assa.inactive_date, assa.address_line1, assa.city, assa.country,
       assa.terms_id, att.name condiciones_pago,
       assa.invoice_currency_code, assa.payment_currency_code,
       assa.ship_to_location_id, assa.bill_to_location_id,
       assa.ship_via_lookup_code, assa.freight_terms_lookup_code,
       assa.fob_lookup_code
FROM ap_suppliers aps,
     ap_supplier_sites_all assa,
     ap_terms_tl att
WHERE aps.vendor_id = assa.vendor_id
    AND assa.org_id = :p_org_id
    AND (:p_vendor_id IS NULL OR aps.vendor_id = :p_vendor_id)
    AND assa.terms_id = att.term_id(+)
    AND att.language(+) = :p_language
ORDER BY aps.vendor_id, assa.vendor_site_id
/
-- Consulta 2: Compradores; nombre HR vigente en la fecha indicada.
-- Conserva compradores sin registro HR para esa fecha.
-- Las fechas de habilitación del comprador se muestran sin excluir inactivos.
SELECT pa.agent_id, papf.full_name comprador_nombre,
       papf.employee_number, papf.business_group_id,
       pa.start_date_active, pa.end_date_active,
       pa.location_id, pa.category_id, pa.authorization_limit,
       papf.effective_start_date, papf.effective_end_date
FROM po_agents pa,
     per_all_people_f papf
WHERE (:p_agent_id IS NULL OR pa.agent_id = :p_agent_id)
    AND pa.agent_id = papf.person_id(+)
    AND papf.effective_start_date(+) <= TO_DATE(:p_fecha_consulta, 'FXYYYY-MM-DD')
    AND papf.effective_end_date(+) >= TO_DATE(:p_fecha_consulta, 'FXYYYY-MM-DD')
ORDER BY pa.agent_id
/
-- Consulta 3: Tipos de línea y valores predeterminados.
SELECT pltb.line_type_id, pltt.line_type, pltt.description,
       pltb.order_type_lookup_code, pltb.category_id,
       pltb.unit_of_measure, pltb.unit_price, pltb.receiving_flag,
       pltb.outside_operation_flag, pltb.inactive_date
FROM po_line_types_b pltb,
     po_line_types_tl pltt
WHERE pltb.line_type_id = pltt.line_type_id(+)
    AND pltt.language(+) = :p_language
    AND (:p_line_type_id IS NULL OR pltb.line_type_id = :p_line_type_id)
ORDER BY pltb.line_type_id
/
-- Consulta 4: Tipos de documento y opciones de aprobación de la OU.
-- No reconstruye las jerarquías ni el resultado del flujo de aprobación.
SELECT pdtab.org_id, pdtab.document_type_code, pdtab.document_subtype,
       pdtat.type_name,
       pdtab.can_preparer_approve_flag,
       pdtab.can_approver_modify_doc_flag,
       pdtab.can_change_approval_path_flag,
       pdtab.forwarding_mode_code,
       pdtab.default_approval_path_id
FROM po_document_types_all_b pdtab,
     po_document_types_all_tl pdtat
WHERE pdtab.org_id = :p_org_id
    AND pdtab.document_type_code = pdtat.document_type_code(+)
    AND pdtab.document_subtype = pdtat.document_subtype(+)
    AND pdtab.org_id = pdtat.org_id(+)
    AND pdtat.language(+) = :p_language
ORDER BY pdtab.document_type_code, pdtab.document_subtype;
