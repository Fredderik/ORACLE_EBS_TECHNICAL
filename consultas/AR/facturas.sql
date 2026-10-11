/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : facturas.sql                                                ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Transacciones AR, líneas y distribuciones.                  ║
║                                                                               ║
║  Parámetros     : Variables de enlace explícitas.                             ║
║    Obligatorios: p_org_id (NUMBER), p_language (código EBS, ej. US).          ║
║    Opcionales (NULL omite el filtro):                                         ║
║    * p_customer_trx_id, p_cust_account_id (NUMBER).                           ║
║    * p_trx_number (VARCHAR2).                                                 ║
║    * p_fecha_desde, p_fecha_hasta (VARCHAR2; YYYY-MM-DD; días inclusivos).    ║
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

-- Se incluyen todas las clases de transacción, completas e incompletas.
-- El cliente filtrado es BILL_TO_CUSTOMER_ID (cuenta, no PARTY_ID).
-- Los tres resultados comparten filtros de cabecera; las fechas son TRX_DATE.
-- Cada / ejecuta el SELECT previo; no colocar ; antes del separador.

-- Consulta 1: Cabecera. El importe es la suma de sus líneas registradas.
-- No representa saldo pendiente ni reconstruye aplicaciones o vencimientos.
SELECT
    h.org_id,
    h.customer_trx_id,
    h.trx_number,
    h.trx_date,
    h.cust_trx_type_id,
    tt.name tipo_transaccion,
    tt.type clase_transaccion,
    h.bill_to_customer_id,
    ca.account_number numero_cliente,
    p.party_name nombre_cliente,
    h.bill_to_site_use_id,
    h.ship_to_customer_id,
    h.ship_to_site_use_id,
    h.invoice_currency_code,
    h.exchange_rate_type,
    h.exchange_date,
    h.exchange_rate,
    h.complete_flag,
    h.term_id,
    t.name condiciones_pago,
    h.purchase_order,
    h.previous_customer_trx_id,
    h.batch_source_id,
    h.receipt_method_id,
    h.comments,
    (SELECT SUM(x.extended_amount)
       FROM ra_customer_trx_lines_all x
      WHERE x.customer_trx_id = h.customer_trx_id
        AND x.org_id = h.org_id) importe_total_lineas
FROM
    ra_customer_trx_all h,
    ra_cust_trx_types_all tt,
    hz_cust_accounts ca,
    hz_parties p,
    ra_terms_tl t
WHERE
    h.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR h.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR h.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR h.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR h.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.cust_trx_type_id = tt.cust_trx_type_id(+)
    AND h.org_id = tt.org_id(+)
    AND h.bill_to_customer_id = ca.cust_account_id(+)
    AND ca.party_id = p.party_id(+)
    AND h.term_id = t.term_id(+)
    AND t.language(+) = :p_language
ORDER BY h.customer_trx_id
/
-- Consulta 2: Cabecera y líneas, incluidas TAX y FREIGHT.
-- Conserva cabeceras sin líneas; no sumar importes entre monedas distintas.
SELECT
    h.org_id,
    h.customer_trx_id,
    h.trx_number,
    h.trx_date,
    h.cust_trx_type_id,
    tt.name tipo_transaccion,
    tt.type clase_transaccion,
    h.bill_to_customer_id,
    ca.account_number numero_cliente,
    p.party_name nombre_cliente,
    h.bill_to_site_use_id,
    h.ship_to_customer_id,
    h.ship_to_site_use_id,
    h.invoice_currency_code,
    h.exchange_rate_type,
    h.exchange_date,
    h.exchange_rate,
    h.complete_flag,
    h.term_id,
    t.name condiciones_pago,
    h.purchase_order,
    h.previous_customer_trx_id,
    h.batch_source_id,
    h.receipt_method_id,
    h.comments,
    l.customer_trx_line_id customer_trx_line_id,
    l.line_number line_number,
    l.line_type line_type,
    l.description descripcion_linea,
    l.quantity_invoiced quantity_invoiced,
    l.quantity_credited quantity_credited,
    l.unit_selling_price unit_selling_price,
    l.extended_amount importe_linea,
    l.link_to_cust_trx_line_id link_to_cust_trx_line_id,
    l.previous_customer_trx_line_id previous_customer_trx_line_id,
    l.sales_order sales_order,
    l.inventory_item_id inventory_item_id
FROM
    ra_customer_trx_all h,
    ra_cust_trx_types_all tt,
    hz_cust_accounts ca,
    hz_parties p,
    ra_terms_tl t,
    ra_customer_trx_lines_all l
WHERE
    h.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR h.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR h.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR h.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR h.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.cust_trx_type_id = tt.cust_trx_type_id(+)
    AND h.org_id = tt.org_id(+)
    AND h.bill_to_customer_id = ca.cust_account_id(+)
    AND ca.party_id = p.party_id(+)
    AND h.term_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.customer_trx_id = l.customer_trx_id(+)
    AND h.org_id = l.org_id(+)
ORDER BY h.customer_trx_id, l.line_number, l.customer_trx_line_id
/
-- Consulta 3: Cabecera, líneas y distribuciones.
-- La subconsulta en FROM, con alias det, no es una tabla de EBS.
-- Su primera rama conserva líneas sin distribución; la segunda incorpora
-- distribuciones sin línea asociada, incluidas las REC de cabecera.
-- UNION ALL conserva cada distribución sin replicar REC por cada línea.
-- ACCOUNT_SET_FLAG = Y identifica modelos de distribución; se muestran junto
-- a los registros reales para diagnóstico, sin sumar ambos como un saldo.
-- Importe_linea se repite cuando hay varias distribuciones de esa línea.
-- Estas distribuciones AR no sustituyen el detalle final de SLA/GL.
SELECT
    h.org_id,
    h.customer_trx_id,
    h.trx_number,
    h.trx_date,
    h.cust_trx_type_id,
    tt.name tipo_transaccion,
    tt.type clase_transaccion,
    h.bill_to_customer_id,
    ca.account_number numero_cliente,
    p.party_name nombre_cliente,
    h.bill_to_site_use_id,
    h.ship_to_customer_id,
    h.ship_to_site_use_id,
    h.invoice_currency_code,
    h.exchange_rate_type,
    h.exchange_date,
    h.exchange_rate,
    h.complete_flag,
    h.term_id,
    t.name condiciones_pago,
    h.purchase_order,
    h.previous_customer_trx_id,
    h.batch_source_id,
    h.receipt_method_id,
    h.comments,
    det.customer_trx_line_id,
    det.line_number,
    det.line_type,
    det.descripcion_linea,
    det.quantity_invoiced,
    det.quantity_credited,
    det.unit_selling_price,
    det.importe_linea,
    det.link_to_cust_trx_line_id,
    det.previous_customer_trx_line_id,
    det.sales_order,
    det.inventory_item_id,
    det.cust_trx_line_gl_dist_id,
    det.linea_distribucion_id,
    det.account_class,
    det.code_combination_id,
    det.importe_distribucion,
    det.importe_contabilizado,
    det.porcentaje_distribucion,
    det.gl_date,
    det.gl_posted_date,
    det.account_set_flag,
    det.latest_rec_flag,
    det.posting_control_id,
    det.event_id
FROM
    ra_customer_trx_all h,
    ra_cust_trx_types_all tt,
    hz_cust_accounts ca,
    hz_parties p,
    ra_terms_tl t,
    (
        SELECT
            l.customer_trx_id,
            l.org_id,
            l.customer_trx_line_id customer_trx_line_id,
            l.line_number line_number,
            l.line_type line_type,
            l.description descripcion_linea,
            l.quantity_invoiced quantity_invoiced,
            l.quantity_credited quantity_credited,
            l.unit_selling_price unit_selling_price,
            l.extended_amount importe_linea,
            l.link_to_cust_trx_line_id link_to_cust_trx_line_id,
            l.previous_customer_trx_line_id previous_customer_trx_line_id,
            l.sales_order sales_order,
            l.inventory_item_id inventory_item_id,
            d.cust_trx_line_gl_dist_id cust_trx_line_gl_dist_id,
            d.customer_trx_line_id linea_distribucion_id,
            d.account_class account_class,
            d.code_combination_id code_combination_id,
            d.amount importe_distribucion,
            d.acctd_amount importe_contabilizado,
            d.percent porcentaje_distribucion,
            d.gl_date gl_date,
            d.gl_posted_date gl_posted_date,
            d.account_set_flag account_set_flag,
            d.latest_rec_flag latest_rec_flag,
            d.posting_control_id posting_control_id,
            d.event_id event_id
        FROM ra_customer_trx_lines_all l,
             ra_cust_trx_line_gl_dist_all d
        WHERE l.org_id = :p_org_id
          AND l.customer_trx_id = d.customer_trx_id(+)
          AND l.customer_trx_line_id = d.customer_trx_line_id(+)
          AND l.org_id = d.org_id(+)
        UNION ALL
        SELECT
            d.customer_trx_id,
            d.org_id,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            d.cust_trx_line_gl_dist_id,
            d.customer_trx_line_id,
            d.account_class,
            d.code_combination_id,
            d.amount,
            d.acctd_amount,
            d.percent,
            d.gl_date,
            d.gl_posted_date,
            d.account_set_flag,
            d.latest_rec_flag,
            d.posting_control_id,
            d.event_id
        FROM ra_cust_trx_line_gl_dist_all d
        WHERE d.org_id = :p_org_id
          AND NOT EXISTS
          (
              SELECT 1
              FROM ra_customer_trx_lines_all lx
              WHERE lx.customer_trx_id = d.customer_trx_id
                AND lx.customer_trx_line_id = d.customer_trx_line_id
                AND lx.org_id = d.org_id
          )
    ) det
WHERE
    h.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR h.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR h.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR h.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR h.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR h.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND h.cust_trx_type_id = tt.cust_trx_type_id(+)
    AND h.org_id = tt.org_id(+)
    AND h.bill_to_customer_id = ca.cust_account_id(+)
    AND ca.party_id = p.party_id(+)
    AND h.term_id = t.term_id(+)
    AND t.language(+) = :p_language
    AND h.customer_trx_id = det.customer_trx_id(+)
    AND h.org_id = det.org_id(+)
ORDER BY h.customer_trx_id, det.line_number, det.customer_trx_line_id,
         det.cust_trx_line_gl_dist_id;
