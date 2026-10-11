/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : requisiciones_ordenes_compra.sql                            ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Origen de órdenes de compra en requisiciones.               ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorio: p_org_id (NUMBER), unidad operativa de requisición.           ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_req_header_id (NUMBER), p_req_number (VARCHAR2).                       ║
║    * p_tipo_requisicion (VARCHAR2: PURCHASE o INTERNAL).                      ║
║    * p_fecha_desde, p_fecha_hasta (VARCHAR2; YYYY-MM-DD).                     ║
║    * p_po_header_id (NUMBER), p_po_number (VARCHAR2).                         ║
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

-- Una fila por distribución de compra vinculada a una distribución de requisición.
-- El vínculo real es pd.req_distribution_id = rd.distribution_id.
-- No se enlazan los números comerciales ni las referencias de requisición en papel.
-- Solo muestra relaciones existentes; no incluye requisiciones sin compra asociada.
-- Las fechas y p_org_id filtran la cabecera de la requisición.
-- La organización de la compra se muestra por separado: no se infiere del origen.
-- Incluye documentos cancelados/cerrados; vínculo no significa compra vigente.
-- Conserva la liberación como opcional para órdenes que no la requieren.
-- No sumar cantidades/importes de requisición repetidos entre compras.
-- No calcula pendiente: unidades, monedas, cancelaciones y divisiones requieren
-- análisis específico. No reconstruye todo el árbol de líneas divididas.
-- No requiere idioma; los estados se muestran con sus códigos originales.

SELECT
    h.org_id, h.requisition_header_id, h.segment1 numero_requisicion,
    h.type_lookup_code tipo_requisicion, h.creation_date,
    h.authorization_status, h.approved_date,
    h.preparer_id preparador_id, h.description,
    h.cancel_flag cancelado_cabecera, h.closed_code cierre_cabecera,
    l.requisition_line_id, l.line_num linea_requisicion,
    l.parent_req_line_id, l.item_id, l.item_description,
    l.unit_meas_lookup_code unidad_requisicion,
    l.quantity cantidad_linea_req, l.to_person_id solicitante_id,
    l.cancel_flag cancelado_linea_req,
    rd.distribution_id distribucion_req_id,
    rd.distribution_num numero_distribucion_req,
    rd.req_line_quantity cantidad_distribucion_req,
    rd.req_line_amount importe_dist_req_funcional,
    rd.req_line_currency_amount, l.currency_code moneda_requisicion,
    rd.code_combination_id cuenta_cargo_req_id,
    ph.org_id organizacion_compra, ph.po_header_id,
    ph.segment1 numero_orden, ph.type_lookup_code tipo_documento_compra,
    ph.creation_date fecha_creacion_compra,
    ph.authorization_status estado_compra,
    ph.cancel_flag cancelado_compra, ph.closed_code cierre_compra,
    ph.vendor_id, ph.vendor_site_id, ph.agent_id comprador_id,
    ph.currency_code moneda_compra,
    pl.po_line_id, pl.line_num linea_compra,
    pl.item_description descripcion_compra,
    pl.unit_meas_lookup_code unidad_compra, pl.unit_price precio_compra,
    pl.cancel_flag cancelado_linea_compra,
    sh.line_location_id, sh.shipment_num, sh.shipment_type,
    sh.need_by_date, sh.promised_date,
    sh.cancel_flag cancelado_envio, sh.closed_code cierre_envio,
    rel.po_release_id, rel.release_num, rel.release_date,
    rel.authorization_status estado_liberacion,
    pd.po_distribution_id, pd.distribution_num numero_distribucion_compra,
    pd.req_distribution_id,
    pd.quantity_ordered cantidad_ordenada_dist,
    pd.quantity_delivered cantidad_entregada_dist,
    pd.quantity_cancelled cantidad_cancelada_dist,
    pd.quantity_billed cantidad_facturada_dist,
    pd.amount_ordered importe_ordenado_dist,
    pd.amount_billed importe_facturado_dist,
    pd.code_combination_id cuenta_cargo_compra_id
FROM
    po_requisition_headers_all h,
    po_requisition_lines_all l,
    po_req_distributions_all rd,
    po_distributions_all pd,
    po_headers_all ph,
    po_lines_all pl,
    po_line_locations_all sh,
    po_releases_all rel
WHERE
    h.org_id = :p_org_id
    AND (:p_req_header_id IS NULL OR h.requisition_header_id = :p_req_header_id)
    AND (:p_req_number IS NULL OR h.segment1 = :p_req_number)
    AND (:p_tipo_requisicion IS NULL OR h.type_lookup_code = :p_tipo_requisicion)
    AND (:p_fecha_desde IS NULL
         OR h.creation_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.creation_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.requisition_header_id = l.requisition_header_id
    AND h.org_id = l.org_id
    AND l.requisition_line_id = rd.requisition_line_id
    AND l.org_id = rd.org_id
    AND rd.distribution_id = pd.req_distribution_id
    AND pd.po_header_id = ph.po_header_id
    AND pd.org_id = ph.org_id
    AND pd.po_line_id = pl.po_line_id
    AND pd.po_header_id = pl.po_header_id
    AND pd.org_id = pl.org_id
    AND pd.line_location_id = sh.line_location_id
    AND pd.po_line_id = sh.po_line_id
    AND pd.po_header_id = sh.po_header_id
    AND pd.org_id = sh.org_id
    AND sh.po_release_id = rel.po_release_id(+)
    AND sh.po_header_id = rel.po_header_id(+)
    AND sh.org_id = rel.org_id(+)
    AND (:p_po_header_id IS NULL OR ph.po_header_id = :p_po_header_id)
    AND (:p_po_number IS NULL OR ph.segment1 = :p_po_number)
ORDER BY h.requisition_header_id, l.line_num, rd.distribution_num,
         ph.po_header_id, pl.line_num, sh.shipment_num, pd.po_distribution_id;
