/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : configuracion_compras.sql                                   ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
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
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Los proveedores se comparten con AP. Para bancos y contactos completos,
-- consultar ../AP/proveedores_configuracion.sql con sus propios parámetros.
-- Sitios y tipos de documento usan la unidad operativa indicada.
-- Compradores y tipos de línea son catálogos globales, no permisos por OU.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Proveedores y sitios de la organización, con indicadores de uso.
-- Incluye sitios sin habilitación de compras para revisar su configuración.
SELECT s.vendor_id, s.segment1 proveedor_numero, s.vendor_name,
       s.enabled_flag, s.start_date_active, s.end_date_active,
       ss.org_id, ss.vendor_site_id, ss.vendor_site_code,
       ss.purchasing_site_flag, ss.rfq_only_site_flag, ss.pay_site_flag,
       ss.inactive_date, ss.address_line1, ss.city, ss.country,
       ss.terms_id, t.name condiciones_pago,
       ss.invoice_currency_code, ss.payment_currency_code,
       ss.ship_to_location_id, ss.bill_to_location_id,
       ss.ship_via_lookup_code, ss.freight_terms_lookup_code,
       ss.fob_lookup_code
FROM ap_suppliers s,
     ap_supplier_sites_all ss,
     ap_terms_tl t
WHERE s.vendor_id = ss.vendor_id
    AND ss.org_id = :p_org_id
    AND (:p_vendor_id IS NULL OR s.vendor_id = :p_vendor_id)
    AND ss.terms_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY s.vendor_id, ss.vendor_site_id
/
-- Consulta 2: Compradores; nombre HR vigente en la fecha indicada.
-- Conserva compradores sin registro HR para esa fecha.
-- Las fechas de habilitación del comprador se muestran sin excluir inactivos.
SELECT a.agent_id, p.full_name comprador_nombre,
       p.employee_number, p.business_group_id,
       a.start_date_active, a.end_date_active,
       a.location_id, a.category_id, a.authorization_limit,
       p.effective_start_date, p.effective_end_date
FROM po_agents a,
     per_all_people_f p
WHERE (:p_agent_id IS NULL OR a.agent_id = :p_agent_id)
    AND a.agent_id = p.person_id(+)
    AND p.effective_start_date(+) <= TO_DATE(:p_fecha_consulta, 'FXYYYY-MM-DD')
    AND p.effective_end_date(+) >= TO_DATE(:p_fecha_consulta, 'FXYYYY-MM-DD')
ORDER BY a.agent_id
/
-- Consulta 3: Tipos de línea y valores predeterminados.
SELECT b.line_type_id, t.line_type, t.description,
       b.order_type_lookup_code, b.category_id,
       b.unit_of_measure, b.unit_price, b.receiving_flag,
       b.outside_operation_flag, b.inactive_date
FROM po_line_types_b b,
     po_line_types_tl t
WHERE b.line_type_id = t.line_type_id(+)
    AND t.language(+) = :p_language
    AND (:p_line_type_id IS NULL OR b.line_type_id = :p_line_type_id)
ORDER BY b.line_type_id
/
-- Consulta 4: Tipos de documento y opciones de aprobación de la OU.
-- No reconstruye las jerarquías ni el resultado del flujo de aprobación.
SELECT b.org_id, b.document_type_code, b.document_subtype,
       t.type_name,
       b.can_preparer_approve_flag,
       b.can_approver_modify_doc_flag,
       b.can_change_approval_path_flag,
       b.forwarding_mode_code,
       b.default_approval_path_id
FROM po_document_types_all_b b,
     po_document_types_all_tl t
WHERE b.org_id = :p_org_id
    AND b.document_type_code = t.document_type_code(+)
    AND b.document_subtype = t.document_subtype(+)
    AND b.org_id = t.org_id(+)
    AND t.language(+) = :p_language
ORDER BY b.document_type_code, b.document_subtype;
