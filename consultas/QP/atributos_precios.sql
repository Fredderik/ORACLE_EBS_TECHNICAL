/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : atributos_precios.sql
║  Autor          : Freddy E. Aparicio M.
║  Fecha creación : 11/10/2026
║  Versión        : 1.0
║  Descripción    : Productos y atributos de las líneas de precio.
║  Parámetros     : p_language obligatorio (texto EBS).
║  Opcionales     : p_list_header_id, p_orig_org_id (NUMBER);
║                   p_currency_code, p_active_flag (texto);
║                   p_fecha_vigencia (texto YYYY-MM-DD).
║  Opcional       : p_list_line_id (NUMBER).
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.
║                   Alias por iniciales; sin contexto de sesión.
║                   Pendiente ejecución nativa en Oracle EBS.
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- Una fila por atributo; se conserva la línea cuando no tiene atributos.
-- Los valores son texto: pueden ser artículos, categorías u otros conceptos.
-- No convertir PRODUCT_ATTR_VALUE indiscriminadamente a NUMBER.
-- La clasificación siguiente corresponde al contexto ITEM estándar.
SELECT
    qlhb.list_header_id, qlht.name nombre_lista, qlhb.currency_code,
    qll.list_line_id, qll.list_line_no, qll.list_line_type_code,
    qll.arithmetic_operator, qll.operand, qll.price_by_formula_id,
    qpa.pricing_attribute_id, qpa.attribute_grouping_no,
    qpa.product_attribute_context, qpa.product_attribute,
    qpa.product_attr_value, qpa.product_uom_code,
    CASE
        WHEN qpa.product_attribute_context = 'ITEM'
         AND qpa.product_attribute = 'PRICING_ATTRIBUTE1' THEN 'Artículo'
        WHEN qpa.product_attribute_context = 'ITEM'
         AND qpa.product_attribute = 'PRICING_ATTRIBUTE2' THEN 'Categoría'
        WHEN qpa.product_attribute_context = 'ITEM'
         AND qpa.product_attribute = 'PRICING_ATTRIBUTE3' THEN 'Todos los artículos'
        ELSE 'Consultar configuración del contexto'
    END tipo_referencia_producto,
    qpa.pricing_attribute_context, qpa.pricing_attribute,
    qpa.pricing_attr_value_from, qpa.pricing_attr_value_to,
    qpa.comparison_operator_code, qpa.excluder_flag,
    qpa.product_attribute_datatype, qpa.pricing_attribute_datatype
FROM qp_list_headers_b qlhb, qp_list_headers_tl qlht,
     qp_list_lines qll, qp_pricing_attributes qpa
WHERE
    qlhb.list_type_code = 'PRL'
    AND :p_language IS NOT NULL
    AND qlhb.list_header_id = qlht.list_header_id(+)
    AND qlht.language(+) = :p_language
    AND (:p_list_header_id IS NULL OR qlhb.list_header_id = :p_list_header_id)
    AND (:p_currency_code IS NULL OR qlhb.currency_code = :p_currency_code)
    AND (:p_active_flag IS NULL OR qlhb.active_flag = :p_active_flag)
    AND (:p_orig_org_id IS NULL OR qlhb.orig_org_id = :p_orig_org_id)
    AND (:p_fecha_vigencia IS NULL
         OR ((qlhb.start_date_active IS NULL
              OR qlhb.start_date_active < TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD') + 1)
         AND (qlhb.end_date_active IS NULL
              OR qlhb.end_date_active >= TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD'))))
    AND qlhb.list_header_id = qll.list_header_id
    AND (:p_fecha_vigencia IS NULL
         OR ((qll.start_date_active IS NULL
              OR qll.start_date_active < TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD') + 1)
         AND (qll.end_date_active IS NULL
              OR qll.end_date_active >= TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD'))))
    AND qll.list_line_id = qpa.list_line_id(+)
    AND (:p_list_line_id IS NULL OR qll.list_line_id = :p_list_line_id)
ORDER BY qlhb.list_header_id, qll.list_line_id, qpa.pricing_attribute_id;
