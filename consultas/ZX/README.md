# ZX — E-Business Tax

Consultas para revisar configuración fiscal y los impuestos registrados en transacciones de Oracle EBS. Muestran datos calculados y configuración, sin ejecutar el motor tributario.

## Archivos

| Archivo | Resultado |
| --- | --- |
| [regimenes_impuestos.sql](regimenes_impuestos.sql) | Dos resultados: regímenes e impuestos por propietario de configuración. |
| [tasas.sql](tasas.sql) | Tasas, tipo de cálculo, vigencia y nombre en el idioma indicado. |
| [impuestos_transaccion.sql](impuestos_transaccion.sql) | Dos resultados: líneas fiscales y sus distribuciones recuperables/no recuperables. |

## Parámetros por archivo

- **regimenes_impuestos.sql**: obligatorios: ninguno. Opcionales: p_tax_regime_code, p_content_owner_id.
- **tasas.sql**: obligatorios: p_language. Opcionales: p_content_owner_id, p_tax_regime_code, p_tax, p_tax_rate_code, p_fecha_vigencia.
- **impuestos_transaccion.sql**: obligatorios: p_application_id, p_entity_code, p_event_class_code, p_trx_id, p_internal_organization_id. Opcionales: p_tax_line_id.

| Parámetro | Tipo |
| --- | --- |
| p_tax_regime_code | VARCHAR2(30) |
| p_content_owner_id | NUMBER |
| p_language | VARCHAR2(4) |
| p_tax | VARCHAR2(30) |
| p_tax_rate_code | VARCHAR2(50) |
| p_fecha_vigencia | VARCHAR2(10), YYYY-MM-DD |
| p_application_id | NUMBER |
| p_entity_code | VARCHAR2(30) |
| p_event_class_code | VARCHAR2(30) |
| p_trx_id | NUMBER |
| p_internal_organization_id | NUMBER |
| p_tax_line_id | NUMBER |

NULL omite un filtro opcional. Los nombres y códigos se comparan por igualdad exacta. En los rangos, la fecha desde es inclusiva y la fecha hasta incluye todo ese día. Introduce fechas válidas en orden ascendente. El idioma es un código instalado en EBS; si falta su traducción, se conserva el registro con descripción vacía.

## Ejemplo de ejecución

Valores ficticios: reemplaza los identificadores, libro y códigos por los de tu entorno. Declara todos los parámetros del archivo, incluso los opcionales. Este bloque prepara las variables de todos los scripts de la carpeta.

~~~sql
VARIABLE p_tax_regime_code VARCHAR2(30)
VARIABLE p_content_owner_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_tax VARCHAR2(30)
VARIABLE p_tax_rate_code VARCHAR2(50)
VARIABLE p_fecha_vigencia VARCHAR2(10)
VARIABLE p_application_id NUMBER
VARIABLE p_entity_code VARCHAR2(30)
VARIABLE p_event_class_code VARCHAR2(30)
VARIABLE p_trx_id NUMBER
VARIABLE p_internal_organization_id NUMBER
VARIABLE p_tax_line_id NUMBER

EXEC :p_tax_regime_code := NULL;
EXEC :p_content_owner_id := NULL;
EXEC :p_language := 'US';
EXEC :p_tax := NULL;
EXEC :p_tax_rate_code := NULL;
EXEC :p_fecha_vigencia := NULL;
EXEC :p_application_id := 200;
EXEC :p_entity_code := 'AP_INVOICES';
EXEC :p_event_class_code := 'STANDARD INVOICES';
EXEC :p_trx_id := 12345;
EXEC :p_internal_organization_id := 101;
EXEC :p_tax_line_id := NULL;

@consultas/ZX/regimenes_impuestos.sql
@consultas/ZX/tasas.sql
@consultas/ZX/impuestos_transaccion.sql
~~~

## Interpretación y alcance

CONTENT_OWNER_ID identifica al propietario de configuración fiscal y no equivale a la unidad operativa. Los impuestos pueden repetir código entre propietarios. p_content_owner_id filtra impuestos y tasas, no el catálogo de regímenes.

En impuestos_transaccion.sql introduce todos los identificadores obligatorios: aplicación, entidad, clase de evento, transacción y organización interna. TRX_ID solo no identifica inequívocamente un documento entre aplicaciones. Los códigos de entidad y clase corresponden a ZX y deben obtenerse del documento y la configuración de tu entorno, sin asumir que coinciden con códigos XLA.

Las líneas incluyen registros cancelados, marcados para eliminación o de monedas de reporte: se muestran sus indicadores para diagnóstico. Las distribuciones también incluyen reversos. No utilizar una suma indiscriminada como total de factura. Se separan los dos resultados para no multiplicar TAX_AMT por cada distribución. Algunas aplicaciones no generan registros en ZX_REC_NREC_DIST; un segundo resultado vacío no implica ausencia de impuesto.

Los importes de transacción y moneda funcional se muestran en columnas distintas. No sumar entre monedas ni confundir porcentajes con tasas por cantidad. tasas.sql conserva tasas inactivas y permite filtrar por vigencia; este filtro no decide su aplicabilidad a una factura ni resuelve tasas por calendario. No se implementan reglas, exenciones ni declaraciones fiscales.

## Convenciones y validación

Oracle EBS R12.1/R12.2 como versiones objetivo. Comentarios en español, cabeceras con autor y versión, alias por iniciales, tablas base y sintaxis tradicional con igualdad y (+). No se obtiene organización o idioma de la sesión. En R12.2 se utilizan los sinónimos estándar de APPS aunque internamente resuelvan a vistas de edición.

Los archivos con varios resultados usan slash en una línea independiente; la consulta previa no termina en punto y coma para evitar su doble ejecución en SQL*Plus. Ejecuta esos archivos en modo script.

Requiere permisos de lectura sobre los objetos referenciados. Se realizó revisión documental y comprobación con datos ficticios; queda pendiente la ejecución nativa en una instancia Oracle EBS y la validación según sus parches.

## Referencias de esquema

- [ZX_TAXES_B — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav429d.html).
- [ZX_RATES_B — eTRM Oracle archivado](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav6c1e.html).
- [ZX_LINES — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavb984.html).
- [ZX_REC_NREC_DIST — eTRM Oracle archivado](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavd72c.html).
