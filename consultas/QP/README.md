# QP — Advanced Pricing

QP administra listas de precios y otros componentes de precios, como modificadores y promociones. Esta carpeta inicia con consultas de diagnóstico de **listas de precios (LIST_TYPE_CODE = 'PRL')** para Oracle EBS R12.1/R12.2.

## Consultas disponibles

| Archivo | Contenido y granularidad |
| --- | --- |
| [listas_precios.sql](listas_precios.sql) | Dos resultados: una fila por cabecera y una por línea de precio. |
| [atributos_precios.sql](atributos_precios.sql) | Una fila por atributo de producto/precio; conserva líneas sin atributos. |
| [calificadores.sql](calificadores.sql) | Una fila por condición de aplicación de la lista. |

Las cabeceras sin líneas aparecen en el primer resultado de listas_precios.sql. Las listas sin calificadores no generan filas en calificadores.sql. La ausencia de calificadores no demuestra por sí sola que una lista sea aplicable a cualquier pedido.

## Parámetros

Declarar todas las variables utilizadas, incluso las opcionales con NULL.

| Variable | Tipo | Uso |
| --- | --- | --- |
| p_language | VARCHAR2(4) | Obligatorio: código de idioma instalado, por ejemplo US. Se conservan registros sin traducción, con nombre vacío. |
| p_list_header_id | NUMBER | Opcional: identificador exacto de lista. |
| p_currency_code | VARCHAR2(15) | Opcional: moneda de cabecera. |
| p_active_flag | VARCHAR2(1) | Opcional: estado de la cabecera, Y/N. No filtra el estado del calificador. |
| p_orig_org_id | NUMBER | Opcional: unidad operativa creadora. No es organización de inventario ni sustituye la seguridad de acceso. |
| p_fecha_vigencia | VARCHAR2(10) | Opcional: YYYY-MM-DD. Conserva intervalos que coincidan con alguna parte de ese día, incluidos extremos abiertos. |
| p_list_line_id | NUMBER | Opcional, solo atributos_precios.sql: línea específica. |

El filtro de fecha se aplica a la cabecera y, según el resultado, a la línea o al calificador. NULL permite revisar históricos y futuros. Estado activo y fechas son filtros independientes. Con todos los filtros opcionales en NULL se consultan todas las listas PRL accesibles por SQL.

GLOBAL_FLAG y ORIG_ORG_ID se muestran para analizar el alcance configurado. Filtrar por la unidad creadora puede omitir listas globales creadas en otras unidades; estas consultas no reproducen las reglas de seguridad ni de elegibilidad del motor de precios.

## Ejemplo en SQL*Plus / SQLcl

~~~sql
VARIABLE p_language VARCHAR2(4)
VARIABLE p_list_header_id NUMBER
VARIABLE p_currency_code VARCHAR2(15)
VARIABLE p_active_flag VARCHAR2(1)
VARIABLE p_orig_org_id NUMBER
VARIABLE p_fecha_vigencia VARCHAR2(10)
VARIABLE p_list_line_id NUMBER

EXEC :p_language := 'US';
EXEC :p_list_header_id := NULL;
EXEC :p_currency_code := NULL;
EXEC :p_active_flag := 'Y';
EXEC :p_orig_org_id := NULL;
EXEC :p_fecha_vigencia := '2026-10-11';
EXEC :p_list_line_id := NULL;

@consultas/QP/listas_precios.sql
@consultas/QP/atributos_precios.sql
@consultas/QP/calificadores.sql
~~~

Sustituye los valores por los de tu entorno. El slash separa y ejecuta la primera consulta de listas_precios.sql; no se coloca punto y coma antes para evitar una ejecución duplicada. Ejecuta el archivo en modo script.

## Interpretación técnica

- QP_LIST_HEADERS_B y QP_LIST_HEADERS_TL contienen cabeceras y traducciones; QP_LIST_LINES contiene líneas.
- QP_PRICING_ATTRIBUTES contiene referencias de producto y condiciones de precio. En el contexto ITEM estándar, PRICING_ATTRIBUTE1 corresponde a artículo, PRICING_ATTRIBUTE2 a categoría y PRICING_ATTRIBUTE3 a todos los artículos. Se conservan los valores originales sin convertirlos a número. Para consultar el artículo en INV se necesita además una organización de inventario explícita; ORIG_ORG_ID no cumple esa función.
- Una línea puede tener varios atributos. OPERAND se repite en ese detalle: no se debe sumar como si fueran importes de transacciones.
- ARITHMETIC_OPERATOR, fórmulas, unidades, rangos, precedencia y configuración intervienen en el cálculo. Estas consultas muestran configuración; no calculan el precio final ni reconstruyen la jerarquía de rupturas de precio mediante QP_RLTD_MODIFIERS.
- QP_QUALIFIERS almacena calificadores. Su significado depende de contexto, atributo, operador, exclusiones y agrupación. Se mantienen separados de los atributos para evitar multiplicaciones de filas; no se evalúa su lógica booleana ni grupos especiales.
- CURRENCY_HEADER_ID identifica la configuración multidivisa cuando corresponde; no se realizan conversiones monetarias.

## Convenciones y validación

Comentarios en español, autor y versión en cabecera, alias por iniciales, relaciones tradicionales mediante igualdad y (+), idioma explícito y tablas base. No se usan vistas funcionales dependientes de sesión. En R12.2 deben utilizarse los sinónimos estándar de APPS, aunque resuelvan internamente a vistas de edición.

Requiere acceso de lectura a los objetos QP indicados. La revisión documental y las pruebas con datos ficticios no sustituyen la ejecución en una instancia Oracle EBS; esa validación queda pendiente.

## Referencias

- [Oracle Advanced Pricing: contextos y atributos estándar R12.1](https://docs.oracle.com/cd/E18727_01/doc.121/e13428/T327893T505653.htm).
- [eTRM Oracle archivado: QP_LIST_HEADERS_B](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavbc6c.html).
- [eTRM Oracle archivado: QP_LIST_LINES](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavc4c5.html).
- [eTRM Oracle archivado: QP_PRICING_ATTRIBUTES](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavc746.html).
- [eTRM Oracle archivado: QP_QUALIFIERS](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnava59e-2.html).
