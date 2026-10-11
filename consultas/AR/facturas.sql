/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : facturas.sql                                                ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 10/10/2026                                                  ║
║  Versión        : 1.1                                                         ║
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
║    11/10/2026: Versión 1.1. Alias por iniciales de tabla.                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Se incluyen todas las clases de transacción, completas e incompletas.
-- El cliente filtrado es BILL_TO_CUSTOMER_ID (cuenta, no PARTY_ID).
-- Los tres resultados comparten filtros de cabecera; las fechas son TRX_DATE.
-- Cada / ejecuta el SELECT previo; no colocar ; antes del separador.

-- Consulta 1: Cabecera. El importe es la suma de sus líneas registradas.
-- No representa saldo pendiente ni reconstruye aplicaciones o vencimientos.
SELECT
    rcta.org_id,
    rcta.customer_trx_id,
    rcta.trx_number,
    rcta.trx_date,
    rcta.cust_trx_type_id,
    rctta.name tipo_transaccion,
    rctta.type clase_transaccion,
    rcta.bill_to_customer_id,
    hca.account_number numero_cliente,
    hp.party_name nombre_cliente,
    rcta.bill_to_site_use_id,
    rcta.ship_to_customer_id,
    rcta.ship_to_site_use_id,
    rcta.invoice_currency_code,
    rcta.exchange_rate_type,
    rcta.exchange_date,
    rcta.exchange_rate,
    rcta.complete_flag,
    rcta.term_id,
    rtt.name condiciones_pago,
    rcta.purchase_order,
    rcta.previous_customer_trx_id,
    rcta.batch_source_id,
    rcta.receipt_method_id,
    rcta.comments,
    (SELECT SUM(rctla.extended_amount)
       FROM ra_customer_trx_lines_all rctla
      WHERE rctla.customer_trx_id = rcta.customer_trx_id
        AND rctla.org_id = rcta.org_id) importe_total_lineas
FROM
    ra_customer_trx_all rcta,
    ra_cust_trx_types_all rctta,
    hz_cust_accounts hca,
    hz_parties hp,
    ra_terms_tl rtt
WHERE
    rcta.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR rcta.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR rcta.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR rcta.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR rcta.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR rcta.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND rcta.cust_trx_type_id = rctta.cust_trx_type_id(+)
    AND rcta.org_id = rctta.org_id(+)
    AND rcta.bill_to_customer_id = hca.cust_account_id(+)
    AND hca.party_id = hp.party_id(+)
    AND rcta.term_id = rtt.term_id(+)
    AND rtt.language(+) = :p_language
ORDER BY rcta.customer_trx_id
/
-- Consulta 2: Cabecera y líneas, incluidas TAX y FREIGHT.
-- Conserva cabeceras sin líneas; no sumar importes entre monedas distintas.
SELECT
    rcta.org_id,
    rcta.customer_trx_id,
    rcta.trx_number,
    rcta.trx_date,
    rcta.cust_trx_type_id,
    rctta.name tipo_transaccion,
    rctta.type clase_transaccion,
    rcta.bill_to_customer_id,
    hca.account_number numero_cliente,
    hp.party_name nombre_cliente,
    rcta.bill_to_site_use_id,
    rcta.ship_to_customer_id,
    rcta.ship_to_site_use_id,
    rcta.invoice_currency_code,
    rcta.exchange_rate_type,
    rcta.exchange_date,
    rcta.exchange_rate,
    rcta.complete_flag,
    rcta.term_id,
    rtt.name condiciones_pago,
    rcta.purchase_order,
    rcta.previous_customer_trx_id,
    rcta.batch_source_id,
    rcta.receipt_method_id,
    rcta.comments,
    rctla.customer_trx_line_id customer_trx_line_id,
    rctla.line_number line_number,
    rctla.line_type line_type,
    rctla.description descripcion_linea,
    rctla.quantity_invoiced quantity_invoiced,
    rctla.quantity_credited quantity_credited,
    rctla.unit_selling_price unit_selling_price,
    rctla.extended_amount importe_linea,
    rctla.link_to_cust_trx_line_id link_to_cust_trx_line_id,
    rctla.previous_customer_trx_line_id previous_customer_trx_line_id,
    rctla.sales_order sales_order,
    rctla.inventory_item_id inventory_item_id
FROM
    ra_customer_trx_all rcta,
    ra_cust_trx_types_all rctta,
    hz_cust_accounts hca,
    hz_parties hp,
    ra_terms_tl rtt,
    ra_customer_trx_lines_all rctla
WHERE
    rcta.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR rcta.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR rcta.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR rcta.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR rcta.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR rcta.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND rcta.cust_trx_type_id = rctta.cust_trx_type_id(+)
    AND rcta.org_id = rctta.org_id(+)
    AND rcta.bill_to_customer_id = hca.cust_account_id(+)
    AND hca.party_id = hp.party_id(+)
    AND rcta.term_id = rtt.term_id(+)
    AND rtt.language(+) = :p_language
    AND rcta.customer_trx_id = rctla.customer_trx_id(+)
    AND rcta.org_id = rctla.org_id(+)
ORDER BY rcta.customer_trx_id, rctla.line_number, rctla.customer_trx_line_id
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
    rcta.org_id,
    rcta.customer_trx_id,
    rcta.trx_number,
    rcta.trx_date,
    rcta.cust_trx_type_id,
    rctta.name tipo_transaccion,
    rctta.type clase_transaccion,
    rcta.bill_to_customer_id,
    hca.account_number numero_cliente,
    hp.party_name nombre_cliente,
    rcta.bill_to_site_use_id,
    rcta.ship_to_customer_id,
    rcta.ship_to_site_use_id,
    rcta.invoice_currency_code,
    rcta.exchange_rate_type,
    rcta.exchange_date,
    rcta.exchange_rate,
    rcta.complete_flag,
    rcta.term_id,
    rtt.name condiciones_pago,
    rcta.purchase_order,
    rcta.previous_customer_trx_id,
    rcta.batch_source_id,
    rcta.receipt_method_id,
    rcta.comments,
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
    ra_customer_trx_all rcta,
    ra_cust_trx_types_all rctta,
    hz_cust_accounts hca,
    hz_parties hp,
    ra_terms_tl rtt,
    (
        SELECT
            rctla.customer_trx_id,
            rctla.org_id,
            rctla.customer_trx_line_id customer_trx_line_id,
            rctla.line_number line_number,
            rctla.line_type line_type,
            rctla.description descripcion_linea,
            rctla.quantity_invoiced quantity_invoiced,
            rctla.quantity_credited quantity_credited,
            rctla.unit_selling_price unit_selling_price,
            rctla.extended_amount importe_linea,
            rctla.link_to_cust_trx_line_id link_to_cust_trx_line_id,
            rctla.previous_customer_trx_line_id previous_customer_trx_line_id,
            rctla.sales_order sales_order,
            rctla.inventory_item_id inventory_item_id,
            rctlgda.cust_trx_line_gl_dist_id cust_trx_line_gl_dist_id,
            rctlgda.customer_trx_line_id linea_distribucion_id,
            rctlgda.account_class account_class,
            rctlgda.code_combination_id code_combination_id,
            rctlgda.amount importe_distribucion,
            rctlgda.acctd_amount importe_contabilizado,
            rctlgda.percent porcentaje_distribucion,
            rctlgda.gl_date gl_date,
            rctlgda.gl_posted_date gl_posted_date,
            rctlgda.account_set_flag account_set_flag,
            rctlgda.latest_rec_flag latest_rec_flag,
            rctlgda.posting_control_id posting_control_id,
            rctlgda.event_id event_id
        FROM ra_customer_trx_lines_all rctla,
             ra_cust_trx_line_gl_dist_all rctlgda
        WHERE rctla.org_id = :p_org_id
          AND rctla.customer_trx_id = rctlgda.customer_trx_id(+)
          AND rctla.customer_trx_line_id = rctlgda.customer_trx_line_id(+)
          AND rctla.org_id = rctlgda.org_id(+)
        UNION ALL
        SELECT
            rctlgda.customer_trx_id,
            rctlgda.org_id,
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
            rctlgda.cust_trx_line_gl_dist_id,
            rctlgda.customer_trx_line_id,
            rctlgda.account_class,
            rctlgda.code_combination_id,
            rctlgda.amount,
            rctlgda.acctd_amount,
            rctlgda.percent,
            rctlgda.gl_date,
            rctlgda.gl_posted_date,
            rctlgda.account_set_flag,
            rctlgda.latest_rec_flag,
            rctlgda.posting_control_id,
            rctlgda.event_id
        FROM ra_cust_trx_line_gl_dist_all rctlgda
        WHERE rctlgda.org_id = :p_org_id
          AND NOT EXISTS
          (
              SELECT 1
              FROM ra_customer_trx_lines_all rctla_2
              WHERE rctla_2.customer_trx_id = rctlgda.customer_trx_id
                AND rctla_2.customer_trx_line_id = rctlgda.customer_trx_line_id
                AND rctla_2.org_id = rctlgda.org_id
          )
    ) det
WHERE
    rcta.org_id = :p_org_id
    AND (:p_customer_trx_id IS NULL OR rcta.customer_trx_id = :p_customer_trx_id)
    AND (:p_trx_number IS NULL OR rcta.trx_number = :p_trx_number)
    AND (:p_cust_account_id IS NULL OR rcta.bill_to_customer_id = :p_cust_account_id)
    AND (:p_fecha_desde IS NULL
         OR rcta.trx_date >= TO_DATE(:p_fecha_desde, 'FXYYYY-MM-DD'))
    AND (:p_fecha_hasta IS NULL
         OR rcta.trx_date < TO_DATE(:p_fecha_hasta, 'FXYYYY-MM-DD') + 1)
    AND rcta.cust_trx_type_id = rctta.cust_trx_type_id(+)
    AND rcta.org_id = rctta.org_id(+)
    AND rcta.bill_to_customer_id = hca.cust_account_id(+)
    AND hca.party_id = hp.party_id(+)
    AND rcta.term_id = rtt.term_id(+)
    AND rtt.language(+) = :p_language
    AND rcta.customer_trx_id = det.customer_trx_id(+)
    AND rcta.org_id = det.org_id(+)
ORDER BY rcta.customer_trx_id, det.line_number, det.customer_trx_line_id,
         det.cust_trx_line_gl_dist_id;
