/*
╔═══════════════════════════════════════════════════════════════════════════════════╗
║  Archivo        : configuracion_gl.sql                                            ║
║  Autor          : Freddy E. Aparicio M.                                           ║
║  Fecha creación : 09/10/2026                                                      ║
║  Versión        : 1.1                                                             ║
║  Descripción    : Libros, períodos abiertos y definición de segmentos.            ║
║                                                                                   ║
║  Parámetros     : Variables de enlace explícitas.                                 ║
║    - Obligatorios:                                                                ║
║      * p_language (VARCHAR2; código EBS, por ejemplo US)                          ║
║    - Opcionales (NULL omite el filtro, salvo indicación):                         ║
║      * p_ledger_id (NUMBER; NULL=todos los libros)                                ║
║                                                                                   ║
║  Notas          : Oracle EBS R12 en adelante; nombres de tablas base.             ║
║                   Uniones por igualdad en WHERE; externas con (+).                ║
║                   Sin valores predeterminados del contexto de sesión.             ║
║                   Pendiente validación de ejecución en Oracle EBS.                ║
║                   Inventario sin filtros de responsabilidad o conjunto de acceso. ║
║                   Tres consultas; la barra / ejecuta el SELECT anterior.          ║
║                                                                                   ║
║  Actualizaciones:                                                                 ║
║    09/10/2026: Versión 1.0. Creación - Freddy E. Aparicio M.                      ║
║    10/10/2026: Versión 1.1. Español y sintaxis SQL tradicional.                   ║
╚═══════════════════════════════════════════════════════════════════════════════════╝
*/

--Consulta 1: Libros individuales, excluidos los conjuntos de libros.
SELECT gl.ledger_id, gl.name, gl.short_name, gl.description,
       gl.ledger_category_code, gl.currency_code,
       gl.chart_of_accounts_id, gl.period_set_name,
       gl.accounted_period_type, gl.completion_status_code,
       gl.enable_average_balances_flag
  FROM gl_ledgers gl
 WHERE gl.object_type_code = 'L'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.name, gl.ledger_id
/
--Consulta 2: Períodos abiertos de GL, incluidos los de ajuste abiertos.
--APPLICATION_ID=101 excluye los estados de período de otras aplicaciones.
SELECT gl.ledger_id, gl.name ledger_name, gps.period_name,
       gps.period_year, gps.period_num, gps.start_date, gps.end_date,
       gps.adjustment_period_flag, gps.closing_status
  FROM gl_ledgers gl,
       gl_period_statuses gps
 WHERE gps.ledger_id = gl.ledger_id
   AND gl.object_type_code = 'L'
   AND gps.application_id = 101
   AND gps.closing_status = 'O'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.ledger_id, gps.period_year, gps.period_num
/
--Consulta 3: El orden visual puede diferir del número de columna SEGMENTn.
--GL_ACCOUNT=cuenta natural. Cada calificador habilitado genera una fila.
--Sin calificador habilitado, el segmento aparece con calificador NULL.
SELECT gl.ledger_id, gl.name ledger_name, gl.chart_of_accounts_id,
       fs.segment_num display_sequence, fs.application_column_name,
       fs.segment_name, fst.form_left_prompt, fst.description,
       fs.enabled_flag, fs.required_flag,
       fs.flex_value_set_id, fvs.flex_value_set_name,
       sav.segment_attribute_type qualifier_code, sav.attribute_value,
       CASE WHEN sav.segment_attribute_type = 'GL_ACCOUNT'
            THEN 'CUENTA_NATURAL'
            ELSE sav.segment_attribute_type END qualifier_meaning
  FROM gl_ledgers gl,
       fnd_id_flex_segments fs,
       fnd_id_flex_segments_tl fst,
       fnd_flex_value_sets fvs,
       fnd_segment_attribute_values sav
 WHERE fs.application_id = 101
   AND fs.id_flex_code = 'GL#'
   AND fs.id_flex_num = gl.chart_of_accounts_id
   AND fst.application_id(+) = fs.application_id
   AND fst.id_flex_code(+) = fs.id_flex_code
   AND fst.id_flex_num(+) = fs.id_flex_num
   AND fst.application_column_name(+) = fs.application_column_name
   AND fst.language(+) = :p_language
   AND fvs.flex_value_set_id(+) = fs.flex_value_set_id
   AND sav.application_id(+) = fs.application_id
   AND sav.id_flex_code(+) = fs.id_flex_code
   AND sav.id_flex_num(+) = fs.id_flex_num
   AND sav.application_column_name(+) = fs.application_column_name
   AND sav.attribute_value(+) = 'Y'
   AND gl.object_type_code = 'L'
   AND (:p_ledger_id IS NULL OR gl.ledger_id = :p_ledger_id)
 ORDER BY gl.ledger_id, fs.segment_num, sav.segment_attribute_type;
