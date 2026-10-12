# FA — Activos fijos

Consultas de Oracle Assets para identificar activos, revisar sus valores actuales por libro, analizar depreciación y consultar el historial de transacciones.

## Archivos

| Archivo | Resultado |
| --- | --- |
| [activos.sql](activos.sql) | Una fila vigente por activo y libro, con descripción, categoría, costo y método de depreciación. |
| [depreciacion.sql](depreciacion.sql) | Una fila por activo, libro y período; gasto y reservas de depreciación. |
| [movimientos.sql](movimientos.sql) | Una fila por cabecera de transacción: altas, ajustes, traslados, bajas y otros tipos. |
| [libros_periodos.sql](libros_periodos.sql) | Dos resultados: libros disponibles y períodos, con filtro de abiertos. |

## Parámetros por archivo

- **activos.sql**: obligatorios: p_book_type_code, p_language. Opcionales: p_asset_id, p_asset_number.
- **depreciacion.sql**: obligatorios: p_book_type_code, p_language. Opcionales: p_asset_id, p_asset_number, p_period_counter.
- **movimientos.sql**: obligatorios: p_book_type_code, p_language. Opcionales: p_asset_id, p_asset_number, p_transaction_type_code, p_fecha_desde, p_fecha_hasta.
- **libros_periodos.sql**: obligatorios: ninguno. Opcionales: p_book_type_code, p_solo_abiertos.

| Parámetro | Tipo |
| --- | --- |
| p_book_type_code | VARCHAR2(15) |
| p_language | VARCHAR2(4) |
| p_asset_id | NUMBER |
| p_asset_number | VARCHAR2(15) |
| p_period_counter | NUMBER |
| p_transaction_type_code | VARCHAR2(20) |
| p_fecha_desde | VARCHAR2(10), YYYY-MM-DD |
| p_fecha_hasta | VARCHAR2(10), YYYY-MM-DD |
| p_solo_abiertos | VARCHAR2(1), Y/N |

NULL omite un filtro opcional. Los nombres y códigos se comparan por igualdad exacta. En los rangos, la fecha desde es inclusiva y la fecha hasta incluye todo ese día. Introduce fechas válidas en orden ascendente. El idioma es un código instalado en EBS; si falta su traducción, se conserva el registro con descripción vacía.

## Ejemplo de ejecución

Valores ficticios: reemplaza los identificadores, libro y códigos por los de tu entorno. Declara todos los parámetros del archivo, incluso los opcionales. Este bloque prepara las variables de todos los scripts de la carpeta.

~~~sql
VARIABLE p_book_type_code VARCHAR2(15)
VARIABLE p_language VARCHAR2(4)
VARIABLE p_asset_id NUMBER
VARIABLE p_asset_number VARCHAR2(15)
VARIABLE p_period_counter NUMBER
VARIABLE p_transaction_type_code VARCHAR2(20)
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)
VARIABLE p_solo_abiertos VARCHAR2(1)

EXEC :p_book_type_code := 'LIBRO_EJEMPLO';
EXEC :p_language := 'US';
EXEC :p_asset_id := NULL;
EXEC :p_asset_number := NULL;
EXEC :p_period_counter := NULL;
EXEC :p_transaction_type_code := NULL;
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;
EXEC :p_solo_abiertos := 'Y';

@consultas/FA/activos.sql
@consultas/FA/depreciacion.sql
@consultas/FA/movimientos.sql
@consultas/FA/libros_periodos.sql
~~~

## Interpretación y alcance

El libro de activos se indica con p_book_type_code; no es una unidad operativa. FA_BOOKS conserva versiones: activos.sql selecciona solo la vigente mediante DATE_INEFFECTIVE y TRANSACTION_HEADER_ID_OUT nulos. Esto no excluye necesariamente activos retirados.

La depreciación no se une al costo vigente para calcular un supuesto valor neto histórico. YTD_DEPRN y DEPRN_RESERVE son acumulados y no deben sumarse entre períodos. La descripción y el número del activo corresponden al maestro actual. Los importes pertenecen al libro seleccionado; estos scripts no consultan las tablas de monedas de reporte FA_MC ni concilian con GL.

movimientos.sql muestra cabeceras, no el detalle monetario de bajas o distribuciones contables. El rango de fechas filtra TRANSACTION_DATE_ENTERED. En libros_periodos.sql, p_solo_abiertos = 'Y' exige PERIOD_CLOSE_DATE nulo en el segundo resultado; NULL o 'N' muestra todos los períodos. Este parámetro no modifica el catálogo de libros.

## Convenciones y validación

Oracle EBS R12.1/R12.2 como versiones objetivo. Comentarios en español, cabeceras con autor y versión, alias por iniciales, tablas base y sintaxis tradicional con igualdad y (+). No se obtiene organización o idioma de la sesión. En R12.2 se utilizan los sinónimos estándar de APPS aunque internamente resuelvan a vistas de edición.

Los archivos con varios resultados usan slash en una línea independiente; la consulta previa no termina en punto y coma para evitar su doble ejecución en SQL*Plus. Ejecuta esos archivos en modo script.

Requiere permisos de lectura sobre los objetos referenciados. Se realizó revisión documental y comprobación con datos ficticios; queda pendiente la ejecución nativa en una instancia Oracle EBS y la validación según sus parches.

## Referencias de esquema

- [FA_BOOKS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav02c8.html).
- [FA_DEPRN_SUMMARY — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd25c.html).
- [FA_TRANSACTION_HEADERS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavbc99.html).
- [FA_BOOK_CONTROLS — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav9f4a.html).
