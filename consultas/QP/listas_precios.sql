/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : listas_precios.sql
║  Autor          : Freddy E. Aparicio M.
║  Fecha creación : 11/10/2026
║  Versión        : 1.0
║  Descripción    : Cabeceras y líneas de listas de precios.
║  Parámetros     : p_language obligatorio (texto EBS).
║  Opcionales     : p_list_header_id, p_orig_org_id (NUMBER);
║                   p_currency_code, p_active_flag (texto);
║                   p_fecha_vigencia (texto YYYY-MM-DD).
║  Notas          : Oracle EBS R12; tablas base y sintaxis tradicional.
║                   Alias por iniciales; sin contexto de sesión.
║                   Pendiente ejecución nativa en Oracle EBS.
║  Actualizaciones: 11/10/2026 — versión 1.0, creación.
╚═══════════════════════════════════════════════════════════════════════════════╝
*/

-- 1. Cabeceras; incluye listas sin líneas y sin traducción solicitada.
-- ORIG_ORG_ID identifica la unidad operativa creadora, no toda la visibilidad.
SELECT
    qlhb.list_header_id, qlht.name nombre_lista,
    qlht.description descripcion_lista, qlht.version_no,
    qlhb.list_type_code, qlhb.currency_code, qlhb.currency_header_id,
    qlhb.active_flag, qlhb.automatic_flag, qlhb.global_flag,
    qlhb.orig_org_id, qlhb.start_date_active, qlhb.end_date_active,
    qlhb.rounding_factor, qlhb.terms_id, qlhb.freight_terms_code,
    qlhb.ship_method_code, qlhb.source_system_code, qlhb.pte_code
FROM qp_list_headers_b qlhb, qp_list_headers_tl qlht
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
ORDER BY qlhb.list_header_id
/
-- 2. Cabeceras y líneas; una fila por línea, sin multiplicar por atributos.
-- OPERAND se interpreta junto con ARITHMETIC_OPERATOR y las fórmulas.
-- No representa necesariamente el precio final calculado para un pedido.
SELECT
    qlhb.list_header_id, qlht.name nombre_lista, qlhb.currency_code,
    qlhb.active_flag, qlhb.orig_org_id, qlhb.global_flag,
    qll.list_line_id, qll.list_line_no, qll.list_line_type_code,
    qll.start_date_active inicio_linea, qll.end_date_active fin_linea,
    qll.arithmetic_operator, qll.operand,
    qll.price_by_formula_id, qll.generate_using_formula_id,
    qll.price_break_type_code, qll.primary_uom_flag,
    qll.product_precedence, qll.comments comentarios_linea
FROM qp_list_headers_b qlhb, qp_list_headers_tl qlht, qp_list_lines qll
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
ORDER BY qlhb.list_header_id, qll.list_line_id;
