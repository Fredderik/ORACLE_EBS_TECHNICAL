/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : calificadores.sql
║  Autor          : Freddy E. Aparicio M.
║  Fecha creación : 11/10/2026
║  Versión        : 1.0
║  Descripción    : Condiciones de aplicación de listas de precios.
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

-- Una fila por calificador de la lista, sin combinar atributos de producto.
-- En listas de precios los calificadores corresponden a la cabecera.
-- No interpretar todos los valores como clientes: dependen del contexto.
-- Se muestran las agrupaciones para su análisis; no se ejecuta el motor QP.
SELECT
    qlhb.list_header_id, qlht.name nombre_lista, qlhb.currency_code,
    qlhb.active_flag lista_activa,
    qq.qualifier_id, qq.list_line_id, qq.qualifier_grouping_no,
    qq.qualifier_context, qq.qualifier_attribute,
    qq.qualifier_attr_value, qq.qualifier_attr_value_to,
    qq.qualifier_datatype, qq.comparison_operator_code, qq.excluder_flag,
    qq.start_date_active inicio_calificador,
    qq.end_date_active fin_calificador,
    qq.active_flag calificador_activo,
    qq.qualifier_rule_id, qq.created_from_rule_id, qq.qualifier_precedence
FROM qp_list_headers_b qlhb, qp_list_headers_tl qlht, qp_qualifiers qq
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
    AND qlhb.list_header_id = qq.list_header_id
    AND (:p_fecha_vigencia IS NULL
         OR ((qq.start_date_active IS NULL
              OR qq.start_date_active < TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD') + 1)
         AND (qq.end_date_active IS NULL
              OR qq.end_date_active >= TO_DATE(:p_fecha_vigencia, 'YYYY-MM-DD'))))
ORDER BY qlhb.list_header_id, qq.qualifier_grouping_no, qq.qualifier_id;
