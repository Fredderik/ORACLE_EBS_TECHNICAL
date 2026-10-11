/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : configuracion_ont.sql                                       ║
║  Autor          : Freddy E. Aparicio M.                                       ║
║  Fecha creación : 11/10/2026                                                  ║
║  Versión        : 1.0                                                         ║
║  Descripción    : Tipos de transacción y orígenes de pedidos.                 ║
║                                                                               ║
║  Parámetros     : Variables de enlace; NULL omite filtros opcionales.         ║
║  Consulta 1: p_org_id (NUMBER) y p_language (texto), obligatorios.            ║
║  Opcionales: p_transaction_type_id (NUMBER),                                  ║
║  p_transaction_type_code (texto), p_fecha_vigencia (YYYY-MM-DD).              ║
║  Consulta 2: p_order_source_id (NUMBER), p_enabled_flag (texto),              ║
║  ambos opcionales; los orígenes son globales, sin filtro por OU.              ║
║                                                                               ║
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.         ║
║                   Alias por iniciales; sin contexto de sesión.                ║
║                   Pendiente ejecución nativa en Oracle EBS.                   ║
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Consulta 1: Tipos de pedido y línea; conserva tipos sin traducción.
-- NULL en fecha incluye vigentes y vencidos. La vigencia se evalúa por día.
SELECT
    otta.org_id, otta.transaction_type_id, otta.transaction_type_code,
    ottt.name nombre_tipo, ottt.description descripcion_tipo,
    otta.order_category_code, otta.start_date_active, otta.end_date_active,
    otta.default_outbound_line_type_id, otta.default_inbound_line_type_id,
    otta.price_list_id, otta.currency_code, otta.warehouse_id,
    otta.cust_trx_type_id, otta.invoice_source_id,
    otta.non_delivery_invoice_source_id,
    otta.invoicing_rule_id, otta.accounting_rule_id,
    otta.entry_credit_check_rule_id, otta.shipping_credit_check_rule_id,
    otta.auto_scheduling_flag
FROM oe_transaction_types_all otta, oe_transaction_types_tl ottt
WHERE
    otta.org_id = :p_org_id
    AND :p_language IS NOT NULL
    AND otta.transaction_type_id = ottt.transaction_type_id(+)
    AND ottt.language(+) = :p_language
    AND (:p_transaction_type_id IS NULL
         OR otta.transaction_type_id = :p_transaction_type_id)
    AND (:p_transaction_type_code IS NULL
         OR otta.transaction_type_code = :p_transaction_type_code)
    AND (:p_fecha_vigencia IS NULL
         OR ((otta.start_date_active IS NULL
              OR otta.start_date_active < TO_DATE(:p_fecha_vigencia, 'FXYYYY-MM-DD') + 1)
             AND (otta.end_date_active IS NULL
                  OR otta.end_date_active >= TO_DATE(:p_fecha_vigencia, 'FXYYYY-MM-DD'))))
ORDER BY otta.transaction_type_code, otta.transaction_type_id
/
-- Consulta 2: Orígenes globales; nombre registrado, sin tabla de traducción.
-- Este catálogo no depende de p_org_id, p_language ni filtros de la consulta 1.
SELECT
    oos.order_source_id, oos.name nombre_origen,
    oos.description descripcion_origen, oos.enabled_flag
FROM oe_order_sources oos
WHERE
    (:p_order_source_id IS NULL OR oos.order_source_id = :p_order_source_id)
    AND (:p_enabled_flag IS NULL OR oos.enabled_flag = :p_enabled_flag)
ORDER BY oos.order_source_id;
