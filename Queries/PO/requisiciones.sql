/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : requisiciones.sql                                           ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Cabecera, líneas y distribuciones de requisiciones.         ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_org_id (NUMBER), unidad operativa de requisición.           ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_req_header_id (NUMBER), p_req_number (VARCHAR2).                       ║
║    * p_tipo_requisicion (VARCHAR2: PURCHASE o INTERNAL).                      ║
║    * p_fecha_desde, p_fecha_hasta (VARCHAR2; YYYY-MM-DD).                     ║
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

-- Incluye requisiciones de compra e internas, también cerradas/canceladas.
-- Las fechas filtran la creación de cabecera, con ambos días inclusivos.
-- No requiere idioma: muestra códigos e información registrada, sin traducciones.
-- No sumar cantidades/importes de línea repetidos por cada distribución.
-- Los importes registrados pueden ser NULL en líneas basadas en cantidad.
-- Cada / ejecuta el SELECT anterior; no colocar ; antes del separador.

-- Consulta 1: Cabecera.
SELECT
    h.org_id, h.requisition_header_id, h.segment1 numero_requisicion,
    h.type_lookup_code tipo_requisicion, h.creation_date,
    h.authorization_status, h.approved_date,
    h.preparer_id preparador_id, h.description,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera
FROM
    po_requisition_headers_all h
WHERE
    h.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR h.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR h.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR h.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY h.requisition_header_id
/
-- Consulta 2: Cabecera y líneas, conservando cabeceras sin líneas.
SELECT
    h.org_id, h.requisition_header_id, h.segment1 numero_requisicion,
    h.type_lookup_code tipo_requisicion, h.creation_date,
    h.authorization_status, h.approved_date,
    h.preparer_id preparador_id, h.description,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    l.requisition_line_id, l.line_num, l.parent_req_line_id,
    l.line_type_id, l.item_id, l.item_description, l.category_id,
    l.unit_meas_lookup_code, l.quantity cantidad_linea,
    l.unit_price precio_moneda_funcional,
    l.currency_code, l.currency_unit_price,
    l.amount importe_linea_funcional, l.currency_amount,
    l.need_by_date, l.to_person_id solicitante_id,
    l.source_type_code, l.destination_type_code,
    l.destination_organization_id, l.destination_subinventory,
    l.deliver_to_location_id, l.suggested_buyer_id,
    l.vendor_id, l.vendor_site_id, l.suggested_vendor_name,
    l.line_location_id envio_referenciado_id,
    l.quantity_delivered, l.quantity_cancelled,
    l.cancel_flag cancelado_linea, l.closed_code cierre_linea
FROM
    po_requisition_headers_all h,
    po_requisition_lines_all l
WHERE
    h.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR h.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR h.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR h.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.requisition_header_id = l.requisition_header_id(+)
    AND h.org_id = l.org_id(+)
ORDER BY h.requisition_header_id, l.line_num, l.requisition_line_id
/
-- Consulta 3: Cabecera, líneas y distribuciones; conserva detalle ausente.
SELECT
    h.org_id, h.requisition_header_id, h.segment1 numero_requisicion,
    h.type_lookup_code tipo_requisicion, h.creation_date,
    h.authorization_status, h.approved_date,
    h.preparer_id preparador_id, h.description,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    l.requisition_line_id, l.line_num, l.parent_req_line_id,
    l.line_type_id, l.item_id, l.item_description, l.category_id,
    l.unit_meas_lookup_code, l.quantity cantidad_linea,
    l.unit_price precio_moneda_funcional,
    l.currency_code, l.currency_unit_price,
    l.amount importe_linea_funcional, l.currency_amount,
    l.need_by_date, l.to_person_id solicitante_id,
    l.source_type_code, l.destination_type_code,
    l.destination_organization_id, l.destination_subinventory,
    l.deliver_to_location_id, l.suggested_buyer_id,
    l.vendor_id, l.vendor_site_id, l.suggested_vendor_name,
    l.line_location_id envio_referenciado_id,
    l.quantity_delivered, l.quantity_cancelled,
    l.cancel_flag cancelado_linea, l.closed_code cierre_linea,
    rd.distribution_id distribucion_req_id, rd.distribution_num,
    rd.req_line_quantity cantidad_distribucion_req,
    rd.req_line_amount importe_dist_req_funcional,
    rd.req_line_currency_amount,
    rd.set_of_books_id, rd.code_combination_id cuenta_cargo_req_id,
    rd.budget_account_id, rd.accrual_account_id, rd.variance_account_id,
    rd.encumbered_flag, rd.gl_encumbered_date,
    rd.project_id, rd.task_id, rd.source_req_distribution_id
FROM
    po_requisition_headers_all h,
    po_requisition_lines_all l,
    po_req_distributions_all rd
WHERE
    h.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR h.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR h.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR h.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.requisition_header_id = l.requisition_header_id(+)
    AND h.org_id = l.org_id(+)
    AND l.requisition_line_id = rd.requisition_line_id(+)
    AND l.org_id = rd.org_id(+)
ORDER BY h.requisition_header_id, l.line_num, l.requisition_line_id,
         rd.distribution_num, rd.distribution_id;
