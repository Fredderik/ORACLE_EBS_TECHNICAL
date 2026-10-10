# AR — Cuentas por cobrar

Consultas técnicas para **Oracle Receivables (AR), Oracle EBS R12 en adelante**, con información de clientes en TCA y cuentas externas de cobro en Oracle Payments.

| Archivo | Contenido |
| --- | --- |
| [facturas.sql](facturas.sql) | Tres resultados: cabecera; cabecera y líneas; cabecera, líneas y distribuciones. |
| [clientes_configuracion.sql](clientes_configuracion.sql) | Seis resultados: cuentas de cliente; sitios y usos; contactos; perfiles de crédito/cobranza; métodos de recibo; cuentas bancarias externas. |

## Convenciones

Cabeceras con autor, versión e historial; comentarios en español; relaciones mediante `=` en `WHERE` y uniones externas con `(+)`. Los scripts consultan tablas base y traducciones explícitas. El idioma y la organización no proceden del contexto de sesión.

Declara todas las variables, también las opcionales. `NULL` omite un filtro opcional. El idioma es un código EBS instalado, por ejemplo `US`. Una traducción ausente deja la descripción en `NULL` sin eliminar el registro.

Ejecuta los archivos completos en modo script. Cada `/` ejecuta el SELECT anterior y no lleva `;` antes; la última consulta termina con `;`. La subconsulta con alias `det` del tercer resultado de facturas es una expresión SQL dentro de `FROM`, **no una tabla adicional de EBS**. Selecciona el bloque completo si ejecutas solo esa consulta.

## Facturas y otras transacciones

Aunque el archivo se llama `facturas.sql`, incluye las clases registradas en AR: facturas, notas de crédito/débito y otras transacciones, tanto completas como incompletas. `clase_transaccion` y `tipo_transaccion` permiten distinguirlas.

Son obligatorios `p_org_id` (unidad operativa, no libro contable) y `p_language`. Los filtros opcionales son `p_customer_trx_id`, `p_trx_number`, `p_cust_account_id`, `p_fecha_desde` y `p_fecha_hasta`. La cuenta filtrada corresponde a `BILL_TO_CUSTOMER_ID`, no al identificador TCA `PARTY_ID`.

Los tres resultados usan los mismos filtros. Las fechas filtran `TRX_DATE`, se introducen como texto `YYYY-MM-DD` e incluyen completos ambos días. Un rango invertido no devuelve filas.

Ejemplo desde la raíz del repositorio, con valores ficticios:

```sql
VARIABLE p_org_id NUMBER
VARIABLE p_language VARCHAR2(4)
VARIABLE p_customer_trx_id NUMBER
VARIABLE p_trx_number VARCHAR2(20)
VARIABLE p_cust_account_id NUMBER
VARIABLE p_fecha_desde VARCHAR2(10)
VARIABLE p_fecha_hasta VARCHAR2(10)

EXEC :p_org_id := 204;
EXEC :p_language := 'US';
EXEC :p_customer_trx_id := NULL;
EXEC :p_trx_number := 'FACTURA-001';
EXEC :p_cust_account_id := 12345;
EXEC :p_fecha_desde := NULL;
EXEC :p_fecha_hasta := NULL;

@Queries/AR/facturas.sql
```

La cabecera incluye cuenta y nombre del cliente, sitios, moneda, condiciones de pago y referencias de transacción. `importe_total_lineas` suma los importes extendidos registrados; no representa saldo pendiente y devuelve `NULL` si no hay líneas.

El segundo resultado conserva cabeceras sin líneas e incluye líneas de artículos, impuestos y fletes. El tercero conserva líneas sin distribuciones y añade las distribuciones sin línea asociada, incluidas las de clase `REC`, **una vez por distribución**. En estas últimas, las columnas de línea quedan en `NULL`; `linea_distribucion_id` permite detectar una referencia a línea inexistente.

No sumes `importe_linea` en el detalle de distribuciones: se repite por cada distribución. Tampoco sumes clases contables distintas como si fueran el total de la factura. Se incluyen registros reales y modelos identificados por `ACCOUNT_SET_FLAG`; revisa este indicador y `LATEST_REC_FLAG` según el análisis. Los importes contabilizados y los de transacción tienen distinta base monetaria.

Las cuentas se muestran por `CODE_COMBINATION_ID`. Estas distribuciones AR no sustituyen los asientos finales SLA/GL. El script no calcula vencimientos, recibos, aplicaciones ni saldo pendiente.

## Clientes y configuración

`p_language` es obligatorio. `p_cust_account_id`, `p_account_number` y `p_org_id` son opcionales. Si introduces ID y número de cuenta, ambos deben coincidir; sin esos filtros se consultan todas las cuentas.

```sql
VARIABLE p_language VARCHAR2(4)
VARIABLE p_cust_account_id NUMBER
VARIABLE p_account_number VARCHAR2(30)
VARIABLE p_org_id NUMBER

EXEC :p_language := 'US';
EXEC :p_cust_account_id := 12345;
EXEC :p_account_number := NULL;
EXEC :p_org_id := 204;

@Queries/AR/clientes_configuracion.sql
```

| Resultado | Nivel y alcance |
| --- | --- |
| Cuenta | Cuenta de cliente y tercero TCA. Global, sin filtro por unidad operativa. Un tercero puede tener varias cuentas. |
| Sitios y usos | Dirección, unidad operativa, estados, usos BILL_TO/SHIP_TO y otros, condiciones y cuentas contables. Conserva sitios sin usos. |
| Contactos | Roles CONTACT de cuenta o sitio y medios de su relación TCA. Una fila por rol y medio; conserva roles sin medios o relación disponible. |
| Perfiles | Configuración de crédito, bloqueos, cobranza y condiciones de cuenta o uso de sitio. No calcula límites disponibles ni incluye perfiles exclusivos de tercero sin cuenta. |
| Métodos de recibo | Asignaciones a cuenta o uso de sitio, principal, método, clase y fechas. |
| Cuentas bancarias | Pagadores de Oracle Payments y asignaciones de cuentas externas para CUSTOMER_PAYMENT/FUNDS_CAPTURE. Conserva pagadores sin cuenta bancaria. |

`p_org_id` limita detalles locales; conserva configuraciones globales. En pagos se comprueba además que el uso de sitio pertenezca a la cuenta consultada. Una asignación global de tercero puede aparecer en varias cuentas del mismo tercero; los identificadores y el nivel de configuración se muestran explícitamente.

Se incluyen registros inactivos y vigencias para diagnóstico. Las consultas muestran configuraciones registradas; no calculan herencia ni determinan qué cuenta seleccionará un cobro. Los números bancarios e IBAN usan los campos enmascarados de Oracle Payments. Las cuentas internas de remesa y el movimiento de recibos quedan fuera del alcance de este script.

El filtro de organización no valida permisos MOAC. Se necesita acceso de lectura a los objetos utilizados.

## Referencias y validación

Estructuras contrastadas con Oracle eTRM (copias archivadas):

- [Cabeceras AR](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnava196.html), [líneas](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavce4b.html) y [distribuciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav4071.html).
- [Cuentas de cliente](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavbbda.html), [sitios](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav6391.html), [usos](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav3264.html) y [roles de contacto](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavb55a.html).
- [Perfiles](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav2805.html), [métodos asignados](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavdc7a.html) y [pagadores externos](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavac37.html).

Se realizaron 33 comprobaciones de lógica sobre nueve consultas con datos ficticios y adaptación temporal a SQLite: filtros, importes, traducciones, distribuciones de cabecera, contactos y alcance de cuentas bancarias. **Pendiente ejecución nativa en Oracle EBS** y validación según versión y parches. En R12.2 se mantienen los sinónimos estándar y su resolución a vistas internas de edición.

[Volver al inicio](../../README.md)
