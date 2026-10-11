/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : requisiciones.sql                                           ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
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
    prha.org_id, prha.requisition_header_id, prha.segment1 numero_requisicion,
    prha.type_lookup_code tipo_requisicion, prha.creation_date,
    prha.authorization_status, prha.approved_date,
    prha.preparer_id preparador_id, prha.description,
    prha.cancel_flag cancelado_cabecera, prha.closed_code cierre_cabecera
FROM
    po_requisition_headers_all prha
WHERE
    prha.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR prha.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR prha.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR prha.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR prha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR prha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
ORDER BY prha.requisition_header_id
/
-- Consulta 2: Cabecera y líneas, conservando cabeceras sin líneas.
SELECT
    prha.org_id, prha.requisition_header_id, prha.segment1 numero_requisicion,
    prha.type_lookup_code tipo_requisicion, prha.creation_date,
    prha.authorization_status, prha.approved_date,
    prha.preparer_id preparador_id, prha.description,
    prha.cancel_flag cancelado_cabecera, prha.closed_code cierre_cabecera,
    prla.requisition_line_id, prla.line_num, prla.parent_req_line_id,
    prla.line_type_id, prla.item_id, prla.item_description, prla.category_id,
    prla.unit_meas_lookup_code, prla.quantity cantidad_linea,
    prla.unit_price precio_moneda_funcional,
    prla.currency_code, prla.currency_unit_price,
    prla.amount importe_linea_funcional, prla.currency_amount,
    prla.need_by_date, prla.to_person_id solicitante_id,
    prla.source_type_code, prla.destination_type_code,
    prla.destination_organization_id, prla.destination_subinventory,
    prla.deliver_to_location_id, prla.suggested_buyer_id,
    prla.vendor_id, prla.vendor_site_id, prla.suggested_vendor_name,
    prla.line_location_id envio_referenciado_id,
    prla.quantity_delivered, prla.quantity_cancelled,
    prla.cancel_flag cancelado_linea, prla.closed_code cierre_linea
FROM
    po_requisition_headers_all prha,
    po_requisition_lines_all prla
WHERE
    prha.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR prha.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR prha.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR prha.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR prha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR prha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND prha.requisition_header_id = prla.requisition_header_id(+)
    AND prha.org_id = prla.org_id(+)
ORDER BY prha.requisition_header_id, prla.line_num, prla.requisition_line_id
/
-- Consulta 3: Cabecera, líneas y distribuciones; conserva detalle ausente.
SELECT
    prha.org_id, prha.requisition_header_id, prha.segment1 numero_requisicion,
    prha.type_lookup_code tipo_requisicion, prha.creation_date,
    prha.authorization_status, prha.approved_date,
    prha.preparer_id preparador_id, prha.description,
    prha.cancel_flag cancelado_cabecera, prha.closed_code cierre_cabecera,
    prla.requisition_line_id, prla.line_num, prla.parent_req_line_id,
    prla.line_type_id, prla.item_id, prla.item_description, prla.category_id,
    prla.unit_meas_lookup_code, prla.quantity cantidad_linea,
    prla.unit_price precio_moneda_funcional,
    prla.currency_code, prla.currency_unit_price,
    prla.amount importe_linea_funcional, prla.currency_amount,
    prla.need_by_date, prla.to_person_id solicitante_id,
    prla.source_type_code, prla.destination_type_code,
    prla.destination_organization_id, prla.destination_subinventory,
    prla.deliver_to_location_id, prla.suggested_buyer_id,
    prla.vendor_id, prla.vendor_site_id, prla.suggested_vendor_name,
    prla.line_location_id envio_referenciado_id,
    prla.quantity_delivered, prla.quantity_cancelled,
    prla.cancel_flag cancelado_linea, prla.closed_code cierre_linea,
    prda.distribution_id distribucion_req_id, prda.distribution_num,
    prda.req_line_quantity cantidad_distribucion_req,
    prda.req_line_amount importe_dist_req_funcional,
    prda.req_line_currency_amount,
    prda.set_of_books_id, prda.code_combination_id cuenta_cargo_req_id,
    prda.budget_account_id, prda.accrual_account_id, prda.variance_account_id,
    prda.encumbered_flag, prda.gl_encumbered_date,
    prda.project_id, prda.task_id, prda.source_req_distribution_id
FROM
    po_requisition_headers_all prha,
    po_requisition_lines_all prla,
    po_req_distributions_all prda
WHERE
    prha.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR prha.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR prha.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR prha.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR prha.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR prha.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND prha.requisition_header_id = prla.requisition_header_id(+)
    AND prha.org_id = prla.org_id(+)
    AND prla.requisition_line_id = prda.requisition_line_id(+)
    AND prla.org_id = prda.org_id(+)
ORDER BY prha.requisition_header_id, prla.line_num, prla.requisition_line_id,
         prda.distribution_num, prda.distribution_id;
